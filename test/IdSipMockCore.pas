unit IdSipMockCore;

interface

uses
  IdSipCore, IdSipHeaders, IdSipMessage, IdSipTransaction, IdSipTransport;

type
  TIdSipMockCore = class(TIdSipAbstractCore)
  private
    fReceiveRequestCalled: Boolean;
    fReceiveResponseCalled: Boolean;
  protected
    procedure ActOnRequest(Request: TIdSipRequest;
                           Transaction: TIdSipTransaction;
                           Receiver: TIdSipTransport); override;
    procedure ActOnResponse(Response: TIdSipResponse;
                            Transaction: TIdSipTransaction;
                            Receiver: TIdSipTransport); override;
    procedure RejectRequest(Reaction: TIdSipUserAgentReaction;
                            Request: TIdSipRequest;
                            Transaction: TIdSipTransaction); override;
    function  WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction; override;
    function  WillAcceptResponse(Response: TIdSipResponse): TIdSipUserAgentReaction; override;
  public
    function  CreateRequest(Dest: TIdSipToHeader): TIdSipRequest; override;
    function  CreateResponse(Request: TIdSipRequest;
                             ResponseCode: Cardinal): TIdSipResponse; override;
    procedure Reset;

    property ReceiveRequestCalled:  Boolean read fReceiveRequestCalled;
    property ReceiveResponseCalled: Boolean read fReceiveResponseCalled;
  end;

  TIdSipMockSession = class(TIdSipSession)
  private
    fIsInboundCall:  Boolean;
    fResponseResent: Boolean;
  public
    constructor Create(UA: TIdSipUserAgentCore); override;

    function  IsInboundCall: Boolean; override;
    procedure ResendLastResponse; override;
    procedure SetIsInboundCall(Value: Boolean);

    property ResponseResent: Boolean read fResponseResent;
  end;

implementation

//******************************************************************************
//* TIdSipMockCore                                                             *
//******************************************************************************
//* TIdSipMockCore Public methods **********************************************

function TIdSipMockCore.CreateRequest(Dest: TIdSipToHeader): TIdSipRequest;
var
  UA: TIdSipUserAgentCore;
begin
  UA := TIdSipUserAgentCore.Create;
  try
    Result := UA.CreateRequest(Dest);
  finally
    UA.Free;
  end;
end;

function TIdSipMockCore.CreateResponse(Request: TIdSipRequest;
                                       ResponseCode: Cardinal): TIdSipResponse;
begin
  Result := nil;
end;

procedure TIdSipMockCore.Reset;
begin
  fReceiveRequestCalled  := true;
  fReceiveResponseCalled := true;
end;

//* TIdSipMockCore Protected methods *******************************************

procedure TIdSipMockCore.ActOnRequest(Request: TIdSipRequest;
                                      Transaction: TIdSipTransaction;
                                      Receiver: TIdSipTransport);
begin
  fReceiveRequestCalled := true;
end;

procedure TIdSipMockCore.ActOnResponse(Response: TIdSipResponse;
                                      Transaction: TIdSipTransaction;
                                      Receiver: TIdSipTransport);
begin
  fReceiveResponseCalled := true;
end;

procedure TIdSipMockCore.RejectRequest(Reaction: TIdSipUserAgentReaction;
                                       Request: TIdSipRequest;
                                       Transaction: TIdSipTransaction);
begin
end;

function TIdSipMockCore.WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction;
begin
  Result := uarAccept;
end;

function TIdSipMockCore.WillAcceptResponse(Response: TIdSipResponse): TIdSipUserAgentReaction;
begin
  Result := uarAccept;
end;

//******************************************************************************
//* TIdSipMockSession                                                          *
//******************************************************************************
//* TIdSipMockSession Public methods *******************************************

constructor TIdSipMockSession.Create(UA: TIdSipUserAgentCore);
begin
  inherited Create(UA);

  Self.CreateInternal;

  Self.fResponseResent := false;
  Self.SetIsInboundCall(false);
end;

function TIdSipMockSession.IsInboundCall: Boolean;
begin
  Result := Self.fIsInboundCall;
end;

procedure TIdSipMockSession.ResendLastResponse;
begin
  Self.fResponseResent := true;
end;

procedure TIdSipMockSession.SetIsInboundCall(Value: Boolean);
begin
  Self.fIsInboundCall := Value;
end;

end.
