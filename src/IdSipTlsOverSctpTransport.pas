unit IdSipTlsOverSctpTransport;

interface

uses
  IdSipMessage, IdSipTransport;

type
  // RFC 3436
  // This class only exists, at the moment, to ensure that we don't assume that
  // TLS over TCP is the only secure transport.
  TIdSipTlsOverSctpTransport = class(TIdSipSctpTransport)
  public
    class function DefaultPort: Cardinal; override;
    class function GetTransportType: String; override;
    class function IsSecure: Boolean; override;
    class function SrvPrefix: String; override;
  end;

implementation

uses
  IdSipConsts, IdSipDns;

class function TIdSipTlsOverSctpTransport.DefaultPort: Cardinal;
begin
  Result := IdPORT_SIPS;
end;

class function TIdSipTlsOverSctpTransport.GetTransportType: String;
begin
  Result := TlsOverSctpTransport;
end;

class function TIdSipTlsOverSctpTransport.IsSecure: Boolean;
begin
  Result := true;
end;

class function TIdSipTlsOverSctpTransport.SrvPrefix: String;
begin
  Result := SrvTlsOverSctpPrefix;
end;

end.
