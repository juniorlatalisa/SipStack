{
  (c) 2004 Directorate of New Technologies, Royal National Institute for Deaf people (RNID)

  The RNID licence covers this unit. Read the licence at:
      http://www.ictrnid.org.uk/docs/gw/rnid_license.txt

  This unit contains code written by:
    * Frank Shearar
}
unit TestIdSipLocator;

interface

uses
  IdSipLocator, IdSipMessage, IdSipMockLocator, TestFramework;

type
  TestTIdSipLocation = class(TTestCase)
  private
    Address:   String;
    Loc:       TIdSipLocation;
    Port:      Cardinal;
    Transport: String;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCopy;
    procedure TestCreate;
    procedure TestCreateFromVia;
  end;

  TestTIdSipLocations = class(TTestCase)
  private
    Locs: TIdSipLocations;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAddLocation;
    procedure TestCount;
    procedure TestIsEmpty;
  end;

  TestTIdSipLocator = class(TTestCase)
  private
    IP:             String;
    Loc:            TIdSipLocator;
    Port:           Cardinal;
    Target:         TIdSipUri;
    TransportParam: String;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestFindServersForResponseWithReceivedParam;
    procedure TestFindServersForResponseWithReceivedParamAndNumericSentBy;
    procedure TestFindServersForResponseWithReceivedParamAndIPv6NumericSentBy;
    procedure TestFindServersForResponseWithNumericSentBy;
    procedure TestNumericAddressNonStandardPort;
    procedure TestNumericAddressUsesUdp;
    procedure TestNumericAddressSipsUriUsesTls;
    procedure TestNumericAddressSipsUriNonStandardPort;
    procedure TestTransportParamTakesPrecedence;
    procedure TestTransportForWithNameAndPort;
    procedure TestTransportForWithNameAndPortSips;
    procedure TestTransportForWithNumericMaddr;
    procedure TestTransportForWithNumericMaddrSips;
    procedure TestTransportForWithTransportParam;
  end;

  TestTIdSipMockLocator = class(TTestCase)
  private
    Loc: TIdSipMockLocator;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAddLocation;
    procedure TestResolveNAPTR;
  end;

implementation

uses
  Classes, IdSipConsts, SysUtils;

function Suite: ITestSuite;
begin
  Result := TTestSuite.Create('IdSipLocator unit tests');
  Result.AddTest(TestTIdSipLocation.Suite);
  Result.AddTest(TestTIdSipLocations.Suite);
  Result.AddTest(TestTIdSipLocator.Suite);
  Result.AddTest(TestTIdSipMockLocator.Suite);
end;

//******************************************************************************
//* TestTIdSipLocation                                                         *
//******************************************************************************
//* TestTIdSipLocation Public methods ******************************************

procedure TestTIdSipLocation.SetUp;
begin
  inherited SetUp;

  Self.Address   := '127.0.0.1';
  Self.Port      := 9999;
  Self.Transport := TcpTransport;

  Self.Loc := TIdSipLocation.Create(Self.Transport, Self.Address, Self.Port);
end;

procedure TestTIdSipLocation.TearDown;
begin
  Self.Loc.Free;

  inherited TearDown;
end;

//* TestTIdSipLocation Published methods ***************************************

procedure TestTIdSipLocation.TestCopy;
var
  Copy: TIdSipLocation;
begin
  Copy := Self.Loc.Copy;
  try
    CheckEquals(Self.Loc.Transport, Copy.Transport, 'Transport');
    CheckEquals(Self.Loc.Address,   Copy.Address,   'Address');
    CheckEquals(Self.Loc.Port,      Copy.Port,      'Port');
  finally
    Copy.Free;
  end;
end;

procedure TestTIdSipLocation.TestCreate;
begin
  CheckEquals(Self.Address,   Self.Loc.Address,   'Address');
  CheckEquals(Self.Port,      Self.Loc.Port,      'Port');
  CheckEquals(Self.Transport, Self.Loc.Transport, 'Transport');
end;

procedure TestTIdSipLocation.TestCreateFromVia;
var
  Loc: TIdSipLocation;
  Via: TIdSipViaHeader;
begin
  Via := TIdSipViaHeader.Create;
  try
    Via.Port      := Self.Port;
    Via.SentBy    := Self.Address;
    Via.Transport := Self.Transport;

    Loc := TIdSipLocation.Create(Via);
    try
      CheckEquals(Via.Port,      Loc.Port,      'Port');
      CheckEquals(Via.SentBy,    Loc.Address,   'Address');
      CheckEquals(Via.Transport, Loc.Transport, 'Transport');
    finally
      Loc.Free;
    end;
  finally
    Via.Free;
  end;
end;

//******************************************************************************
//* TestTIdSipLocations                                                        *
//******************************************************************************
//* TestTIdSipLocations Public methods *****************************************

procedure TestTIdSipLocations.SetUp;
begin
  inherited SetUp;

  Self.Locs := TIdSipLocations.Create;
end;

procedure TestTIdSipLocations.TearDown;
begin
  Self.Locs.Free;

  inherited TearDown;
end;

//* TestTIdSipLocations Published methods **************************************

procedure TestTIdSipLocations.TestAddLocation;
const
  Transport = TcpTransport;
  Address   = 'foo.com';
  Port      = IdPORT_SIP;
begin
  Self.Locs.AddLocation(Transport, Address, Port);

  CheckEquals(Transport, Self.Locs.First.Transport, 'Transport');
  CheckEquals(Address,   Self.Locs.First.Address,   'Address');
  CheckEquals(Port,      Self.Locs.First.Port,      'Port');
end;

procedure TestTIdSipLocations.TestCount;
var
  I: Integer;
begin
  CheckEquals(0, Self.Locs.Count, 'Empty list');

  for I := 1 to 5 do begin
    Self.Locs.AddLocation(TcpTransport, 'foo.com', I);
    CheckEquals(I,
                Self.Locs.Count,
                'Added ' + IntToStr(I) + ' item(s)');
  end;
end;

procedure TestTIdSipLocations.TestIsEmpty;
var
  I: Integer;
begin
  Check(Self.Locs.IsEmpty, 'Empty list');

  for I := 1 to 5 do begin
    Self.Locs.AddLocation(TcpTransport, 'foo.com', I);
    Check(not Self.Locs.IsEmpty,
          'IsEmpty after ' + IntToStr(I) + ' item(s)');
  end;
end;

//******************************************************************************
//* TestTIdSipLocator                                                          *
//******************************************************************************
//* TestTIdSipLocator Public methods *******************************************

procedure TestTIdSipLocator.SetUp;
begin
  inherited SetUp;

  Self.IP     := '1.2.3.4';
  Self.Loc    := TIdSipLocator.Create;
  Self.Port   := IdPORT_SIP;
  Self.Target := TIdSipUri.Create;
end;

procedure TestTIdSipLocator.TearDown;
begin
  Self.Target.Free;
  Self.Loc.Free;

  inherited Destroy;
end;

//* TestTIdSipLocator Published methods ****************************************

procedure TestTIdSipLocator.TestFindServersForResponseWithReceivedParam;
var
  Locations: TIdSipLocations;
  Response:  TIdSipResponse;
begin
  Response := TIdSipResponse.Create;
  try
    Response.AddHeader(ViaHeaderFull).Value := 'SIP/2.0/UDP gw1.leo-ix.net;received=' + Self.IP;

    Locations := Self.Loc.FindServersFor(Response);
    try
      CheckEquals(Response.LastHop.Transport,
                  Locations[0].Transport,
                  'First location transport');
      CheckEquals(Response.LastHop.Received,
                  Locations[0].Address,
                  'First location address');
      CheckEquals(Response.LastHop.Port,
                  Locations[0].Port,
                  'First location port');
    finally
      Locations.Free;
    end;
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipLocator.TestFindServersForResponseWithReceivedParamAndNumericSentBy;
const
  SentByIP = '6.6.6.6';
var
  Locations: TIdSipLocations;
  Response:  TIdSipResponse;
begin
  Response := TIdSipResponse.Create;
  try
    Response.AddHeader(ViaHeaderFull).Value := 'SIP/2.0/UDP ' + SentByIP + ';received=' + Self.IP;

    Locations := Self.Loc.FindServersFor(Response);
    try
      CheckEquals(Response.LastHop.Transport,
                  Locations[1].Transport,
                  'First location transport');
      CheckEquals(SentByIP,
                  Locations[1].Address,
                  'First location address');
      CheckEquals(Response.LastHop.Port,
                  Locations[1].Port,
                  'First location port');
    finally
      Locations.Free;
    end;
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipLocator.TestFindServersForResponseWithReceivedParamAndIpv6NumericSentBy;
const
  SentByIP = '[2002:dead:beef:1::1]';
var
  Locations: TIdSipLocations;
  Response:  TIdSipResponse;
begin
  Response := TIdSipResponse.Create;
  try
    Response.AddHeader(ViaHeaderFull).Value := 'SIP/2.0/UDP ' + SentByIP + ';received=' + Self.IP;

    Locations := Self.Loc.FindServersFor(Response);
    try
      CheckEquals(Response.LastHop.Transport,
                  Locations[1].Transport,
                  'First location transport');
      CheckEquals(SentByIP,
                  Locations[1].Address,
                  'First location address');
      CheckEquals(Response.LastHop.Port,
                  Locations[1].Port,
                  'First location port');
    finally
      Locations.Free;
    end;
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipLocator.TestFindServersForResponseWithNumericSentBy;
var
  Locations: TIdSipLocations;
  Response:  TIdSipResponse;
begin
  Response := TIdSipResponse.Create;
  try
    Response.AddHeader(ViaHeaderFull).Value := 'SIP/2.0/UDP ' + Self.IP;

    Locations := Self.Loc.FindServersFor(Response);
    try
      CheckEquals(Response.LastHop.Transport,
                  Locations[0].Transport,
                  'First location transport');
      CheckEquals(Self.IP,
                  Locations[0].Address,
                  'First location address');
      CheckEquals(Response.LastHop.Port,
                  Locations[0].Port,
                  'First location port');
    finally
      Locations.Free;
    end;
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipLocator.TestNumericAddressNonStandardPort;
var
  Locations: TIdSipLocations;
begin
  Self.Port       := 3000;
  Self.Target.Uri := 'sip:' + IP + ':' + IntToStr(Self.Port);

  Locations := Self.Loc.FindServersFor(Self.Target.Uri);
  try
    CheckEquals(UdpTransport, Locations.First.Transport, 'Transport');
    CheckEquals(Self.IP,      Locations.First.Address,   'Address');
    CheckEquals(Self.Port,    Locations.First.Port,      'Port');
  finally
    Locations.Free;
  end;
end;

procedure TestTIdSipLocator.TestNumericAddressUsesUdp;
var
  Locations: TIdSipLocations;
begin
  Self.Target.Uri := 'sip:' + Self.IP;

  Locations := Self.Loc.FindServersFor(Self.Target.Uri);
  try
    CheckEquals(UdpTransport, Locations.First.Transport, 'Transport');
    CheckEquals(Self.IP,      Locations.First.Address,   'Address');
    CheckEquals(Self.Port,    Locations.First.Port,      'Port');
  finally
    Locations.Free;
  end;
end;

procedure TestTIdSipLocator.TestNumericAddressSipsUriUsesTls;
var
  Locations: TIdSipLocations;
begin
  Self.Port       := IdPORT_SIPS;
  Self.Target.Uri := 'sips:' + Self.IP;

  Locations := Self.Loc.FindServersFor(Self.Target.Uri);
  try
    CheckEquals(TlsTransport, Locations.First.Transport, 'Transport');
    CheckEquals(Self.IP,      Locations.First.Address,   'Address');
    CheckEquals(Self.Port,    Locations.First.Port,      'Port');
  finally
    Locations.Free;
  end;
end;

procedure TestTIdSipLocator.TestNumericAddressSipsUriNonStandardPort;
var
  Locations: TIdSipLocations;
begin
  Self.Port       := 3000;
  Self.Target.Uri := 'sips:' + Self.IP + ':' + IntToStr(Self.Port);

  Locations := Self.Loc.FindServersFor(Self.Target.Uri);
  try
    CheckEquals(TlsTransport, Locations.First.Transport, 'Transport');
    CheckEquals(Self.IP,      Locations.First.Address,   'Address');
    CheckEquals(Self.Port,    Locations.First.Port,      'Port');
  finally
    Locations.Free;
  end;
end;

procedure TestTIdSipLocator.TestTransportParamTakesPrecedence;
var
  Locations: TIdSipLocations;
begin
  Self.TransportParam := TransportParamSCTP;
  Self.Target.Uri := 'sip:foo.com;transport=' + Self.TransportParam;

  Locations := Self.Loc.FindServersFor(Self.Target.Uri);
  try
    CheckEquals(ParamToTransport(Self.TransportParam),
                Locations.First.Transport,
                'Transport');
  finally
    Locations.Free;
  end;
end;

procedure TestTIdSipLocator.TestTransportForWithNameAndPort;
begin
  Self.Target.Uri := 'sip:foo.com:5060';

  CheckEquals(UdpTransport,
              Self.Loc.TransportFor(Self.Target),
              'Name:Port');
end;

procedure TestTIdSipLocator.TestTransportForWithNameAndPortSips;
begin
  Self.Target.Uri := 'sips:foo.com:5060';

  CheckEquals(TcpTransport,
              Self.Loc.TransportFor(Self.Target),
              'SIPS Name:Port');
end;

procedure TestTIdSipLocator.TestTransportForWithNumericMaddr;
begin
  Self.Target.Uri := 'sip:foo.com;maddr=127.0.0.1';

  CheckEquals(UdpTransport,
              Self.Loc.TransportFor(Self.Target),
              'Numeric IPv4 maddr');

  Self.Target.Uri := 'sip:foo.com;maddr=::1';

  CheckEquals(UdpTransport,
              Self.Loc.TransportFor(Self.Target),
              'Numeric IPv6 maddr');
end;

procedure TestTIdSipLocator.TestTransportForWithNumericMaddrSips;
begin
  Self.Target.Uri := 'sips:foo.com;maddr=127.0.0.1';

  CheckEquals(TcpTransport,
              Self.Loc.TransportFor(Self.Target),
              'Numeric IPv4 maddr');

  Self.Target.Uri := 'sips:foo.com;maddr=::1';

  CheckEquals(TcpTransport,
              Self.Loc.TransportFor(Self.Target),
              'Numeric IPv6 maddr');
end;

procedure TestTIdSipLocator.TestTransportForWithTransportParam;
begin
  Self.TransportParam := TransportParamSCTP;
  Self.Target.Uri := 'sip:foo.com;transport=' + Self.TransportParam;

  CheckEquals(ParamToTransport(Self.TransportParam),
              Self.Loc.TransportFor(Self.Target),
              'Transport param ueber alles');
end;

//******************************************************************************
//* TestTIdSipMockLocator                                                      *
//******************************************************************************
//* TestTIdSipMockLocator Public methods ***************************************

procedure TestTIdSipMockLocator.SetUp;
begin
  inherited SetUp;

  Self.Loc := TIdSipMockLocator.Create;
end;

procedure TestTIdSipMockLocator.TearDown;
begin
  Self.Loc.Free;

  inherited TearDown;
end;

//* TestTIdSipMockLocator Published methods ************************************

procedure TestTIdSipMockLocator.TestAddLocation;
const
  AOR       = 'sip:foo@bar';
  Address   = '1.2.3.4';
  Port      = 15060;
  Transport = 'SCTP';
var
  Location: TIdSipLocation;
begin
  Self.Loc.AddLocation(AOR, Transport, Address, Port);

  Location := Self.Loc.FindServersFor(AOR).First;

  CheckEquals(Address,   Location.Address,   'IPAddress');
  CheckEquals(Port,      Location.Port,      'Port');
  CheckEquals(Transport, Location.Transport, 'Transport');
end;

procedure TestTIdSipMockLocator.TestResolveNAPTR;
const
  AOR = 'bar';
var
  Results: TStrings;
begin
  Self.Loc.AddNAPTR(AOR,   20, 10, 's', 'SIP+D2T',  '_sip._tcp.bar');
  Self.Loc.AddNAPTR(AOR,   10, 10, 's', 'SIPS+D2T', '_sips._tls.bar');
  Self.Loc.AddNAPTR(AOR,   30, 10, 's', 'SIP+D2U',  '_sip._udp.bar');
  Self.Loc.AddNAPTR('foo', 30, 10, 's', 'SIP+D2U',  '_sip._udp.foo');

  Results := Self.Loc.ResolveNAPTR(AOR);
  try
    CheckEquals(3,
                Results.Count,
                'Incorrect number of results: unwanted records added?');

    CheckEquals('_sips._tls.bar', Results[0], '1st record');
    CheckEquals('_sip._tcp.bar',  Results[1], '2nd record');
    CheckEquals('_sip._udp.bar',  Results[2], '3rd record');
  finally
    Results.Free;
  end;
end;

initialization
  RegisterTest('SIP Location Services', Suite);
end.
