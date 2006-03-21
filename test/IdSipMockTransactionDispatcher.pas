{
  (c) 2004 Directorate of New Technologies, Royal National Institute for Deaf people (RNID)

  The RNID licence covers this unit. Read the licence at:
      http://www.ictrnid.org.uk/docs/gw/rnid_license.txt

  This unit contains code written by:
    * Frank Shearar
}
unit IdSipMockTransactionDispatcher;

interface

uses
  Classes, IdSipLocator, IdSipMessage, IdSipMockLocator, IdSipMockTransport,
  IdSipTransaction, IdSipTransport, IdTimerQueue;

type
  TIdSipMockTransactionDispatcher = class(TIdSipTransactionDispatcher)
  private
    SentAcks:      TIdSipRequestList;
    SentRequests:  TIdSipRequestList;
    SentResponses: TIdSipResponseList;
    fTransportType: String;

    function GetDebugTimer: TIdDebugTimerQueue;
    function GetMockLocator: TIdSipMockLocator;
    function GetTransport: TIdSipMockTransport;
  protected
    procedure OnReceiveRequest(Request: TIdSipRequest;
                               Receiver: TIdSipTransport;
                               Source: TIdSipConnectionBindings); overload; override;
    procedure OnReceiveResponse(Response: TIdSipResponse;
                                Receiver: TIdSipTransport;
                                Source: TIdSipConnectionBindings); overload; override;
  public
    constructor Create; reintroduce;
    destructor  Destroy; override;

    procedure AddTransportSendingListener(Listener: IIdSipTransportSendingListener);
    function  LastAck: TIdSipRequest;
    function  LastRequest: TIdSipRequest;
    function  LastResponse: TIdSipResponse;
    procedure SendToTransport(Msg: TIdSipMessage;
                              Dest: TIdSipLocation); overload; override;
    procedure SendToTransport(Response: TIdSipResponse;
                              Dests: TIdSipLocations); override;
    function  SentAckCount: Cardinal;
    function  SentRequestCount:  Cardinal;
    function  SentResponseCount: Cardinal;

    property DebugTimer:    TIdDebugTimerQueue  read GetDebugTimer;
    property MockLocator:   TIdSipMockLocator   read GetMockLocator;
    property Transport:     TIdSipMockTransport read GetTransport;
    property TransportType: String              read fTransportType write fTransportType;
  end;

implementation

uses
  IdSipConsts, SysUtils;

const
  NoDestinationsForResponse = 'Couldn''t send the response because there are '
                            + 'no destinations for ''%s'': check your A/AAAA/etc '
                            + 'setup in your mock locator';

//******************************************************************************
//* TIdSipMockTransactionDispatcher                                            *
//******************************************************************************
//* TIdSipMockTransactionDispatcher Public methods *****************************

constructor TIdSipMockTransactionDispatcher.Create;
var
  I:              Integer;
  SupportedTrans: TStrings;
begin
  inherited Create(TIdDebugTimerQueue.Create(false), TIdSipMockLocator.Create);

  Self.SentAcks      := TIdSipRequestList.Create;
  Self.SentRequests  := TIdSipRequestList.Create;
  Self.SentResponses := TIdSipResponseList.Create;

  Self.DebugTimer.TriggerImmediateEvents := true;

  TIdSipTransportRegistry.RegisterTransportType(TcpTransport, TIdSipMockTcpTransport);
  TIdSipTransportRegistry.RegisterTransportType(TlsTransport, TIdSipMockTlsTransport);
  TIdSipTransportRegistry.RegisterTransportType(UdpTransport, TIdSipMockUdpTransport);

  Self.TransportType := UdpTransport;

  SupportedTrans := TStringList.Create;
  try
    TIdSipTransportRegistry.SecureTransports(SupportedTrans);
    TIdSipTransportRegistry.InSecureTransports(SupportedTrans);

    for I := 0 to SupportedTrans.Count - 1 do begin
      Self.AddTransportBinding(SupportedTrans[I],
                               '127.0.0.1',
                               TIdSipTransportRegistry.TransportTypeFor(SupportedTrans[I]).DefaultPort);
    end;
  finally
    SupportedTrans.Free;
  end;
end;

destructor TIdSipMockTransactionDispatcher.Destroy;
begin
  Self.Timer.Terminate;
  Self.Locator.Free;

  TIdSipTransportRegistry.UnregisterTransportType(TcpTransport);
  TIdSipTransportRegistry.UnregisterTransportType(TlsTransport);
  TIdSipTransportRegistry.UnregisterTransportType(UdpTransport);

  Self.SentResponses.Free;
  Self.SentRequests.Free;
  Self.SentAcks.Free;

  inherited Destroy;
end;

procedure TIdSipMockTransactionDispatcher.AddTransportSendingListener(Listener: IIdSipTransportSendingListener);
var
  I: Integer;
begin
  for I := 0 to Self.Transports.Count - 1 do
    Self.Transports[I].AddTransportSendingListener(Listener);
end;

function TIdSipMockTransactionDispatcher.LastAck: TIdSipRequest;
begin
  Result := Self.SentAcks.Last;
end;

function TIdSipMockTransactionDispatcher.LastRequest: TIdSipRequest;
begin
  Result := Self.SentRequests.Last;
end;

function TIdSipMockTransactionDispatcher.LastResponse: TIdSipResponse;
begin
  Result := Self.SentResponses.Last;
end;

procedure TIdSipMockTransactionDispatcher.SendToTransport(Msg: TIdSipMessage;
                                                          Dest: TIdSipLocation);
begin
  if Msg.IsResponse then begin
    Self.SentResponses.AddCopy(Msg as TIdSipResponse);
  end
  else begin
    if Msg.IsAck then
      Self.SentAcks.AddCopy(Msg as TIdSipRequest)
    else
      Self.SentRequests.AddCopy(Msg as TIdSipRequest);
  end;

  inherited SendToTransport(Msg, Dest);
end;

procedure TIdSipMockTransactionDispatcher.SendToTransport(Response: TIdSipResponse;
                                                          Dests: TIdSipLocations);
begin
  if Dests.IsEmpty then
    raise Exception.Create(Format(NoDestinationsForResponse, [Response.LastHop.SentBy]));

  Self.Transport.Send(Response, Dests[0]);
end;

function TIdSipMockTransactionDispatcher.SentAckCount: Cardinal;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Self.TransportCount - 1 do
    Result := Result + (Self.Transports[I] as TIdSipMockTransport).ACKCount;
end;

function TIdSipMockTransactionDispatcher.SentRequestCount:  Cardinal;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Self.TransportCount - 1 do
    Result := Result + (Self.Transports[I] as TIdSipMockTransport).SentRequestCount;
end;

function TIdSipMockTransactionDispatcher.SentResponseCount: Cardinal;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Self.TransportCount - 1 do
    Result := Result + (Self.Transports[I] as TIdSipMockTransport).SentResponseCount;
end;

procedure TIdSipMockTransactionDispatcher.OnReceiveRequest(Request: TIdSipRequest;
                                                           Receiver: TIdSipTransport;
                                                           Source: TIdSipConnectionBindings);
begin
  if Request.IsAck then
    Self.SentAcks.AddCopy(Request)
  else
    Self.SentRequests.AddCopy(Request);

  inherited OnReceiveRequest(Request, Receiver, Source);
end;

procedure TIdSipMockTransactionDispatcher.OnReceiveResponse(Response: TIdSipResponse;
                                                            Receiver: TIdSipTransport;
                                                            Source: TIdSipConnectionBindings);
begin
  Self.SentResponses.AddCopy(Response);

  inherited OnReceiveResponse(Response, Receiver, Source);
end;

//* TIdSipMockTransactionDispatcher Private methods ****************************

function TIdSipMockTransactionDispatcher.GetDebugTimer: TIdDebugTimerQueue;
begin
  Result := Self.Timer as TIdDebugTimerQueue;
end;

function TIdSipMockTransactionDispatcher.GetMockLocator: TIdSipMockLocator;
begin
  Result := Self.Locator as TIdSipMockLocator;
end;

function TIdSipMockTransactionDispatcher.GetTransport: TIdSipMockTransport;
var
  Index: Integer;
begin
  Index := 0;
  while (Index < Self.TransportCount)
    and (Self.Transports[Index].GetTransportType <> Self.TransportType) do
    Inc(Index);

  if (Index < Self.TransportCount) then
     Result := Self.Transports[Index] as TIdSipMockTransport
  else
    raise Exception.Create('TIdSipMockTransactionDispatcher doesn''t know '
                         + 'about transport ''' + Self.TransportType + '''');
end;

end.
