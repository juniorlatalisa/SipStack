unit IdSipMessage;

interface

uses
  Classes, Contnrs, IdDateTimeStamp, IdGlobal, IdInterfacedObject,
  IdSimpleParser, SyncObjs, SysUtils;

type
  TIdSipQValue = 0..1000;
  TIdSipTransportType = (sttSCTP, sttTCP, sttTLS, sttUDP, sttNULL);

  TIdSipChars = set of Char;

type
  TIdSipRequest = class;
  TIdSipResponse = class;

  TIdSipNotifyEvent = TNotifyEvent;

  IIdSipMessageVisitor = interface
    ['{E2900B55-A1CA-47F1-9DB0-D72D6A846EA0}']
    procedure VisitRequest(Request: TIdSipRequest);
    procedure VisitResponse(Response: TIdSipResponse);
  end;

  TIdSipHeader = class;
  TIdSipHeaders = class;

  TIdUri = class(TObject)
  private
    fScheme: String;
  public
    function AsString: String; virtual;
    function IsSipUri: Boolean; virtual;

    property Scheme: String read fScheme write fScheme;
  end;

  TIdSipRouteHeader = class;

  TIdSipUri = class(TIdUri)
  private
    fHeaders:         TIdSipHeaders;
    fHost:            String;
    fPassword:        String;
    fPort:            Cardinal;
    fPortIsSpecified: Boolean;
    fUsername:        String;
    Parameters:       TStrings;

    class function IsEscapedOrInSet(const Token: String;
                                    AcceptableChars: TIdSipChars): Boolean;

    function  EqualParameters(const Uri: TIdSipUri): Boolean;
    function  GetMaddr: String;
    function  GetMethod: String;
    function  GetTransport: String;
    function  GetTTL: Cardinal;
    function  GetUri: String;
    function  GetUserParameter: String;
    function  HasValidHostInfo: Boolean;
    function  HasValidParameters: Boolean;
    function  HasValidScheme: Boolean;
    function  HasValidUserInfo: Boolean;
    function  HeadersAsString: String;
    function  IsKnownParameter(const Name: String): Boolean;
    function  ParamsAsString: String;
    procedure Parse(Uri: String);
    procedure ParseHeaders(HeaderList: String);
    procedure ParseHost(HostAndPort: String);
    procedure ParseParams(ParamList: String);
    procedure ParseUserInfo(UserInfo: String);
    procedure Reset;
    procedure SetMaddr(const Value: String);
    procedure SetMethod(const Value: String);
    procedure SetPort(const Value: Cardinal);
    procedure SetTransport(const Value: String);
    procedure SetTTL(const Value: Cardinal);
    procedure SetUri(const Value: String);
    procedure SetUserParameter(const Value: String);
    function  UnidirectionalParameterCompare(ThisUri, ThatUri: TIdSipUri): Boolean;
  public
    class function CreateUri(URI: String = ''): TIdUri;
    class function Decode(const Src: String): String;
    class function Encode(const Src: String;
                          const SafeChars: TIdSipChars): String;
    class function HeaderEncode(const NameOrValue: String): String;
    class function IsParamNameOrValue(const Token: String): Boolean;
    class function IsPassword(const Token: String): Boolean;
    class function IsUser(const Token: String): Boolean;
    class function ParameterEncode(const Parameter: String): String; //; override;
    class function UsernameEncode(const Username: String): String;

    constructor Create(URI: String = ''); virtual;
    destructor  Destroy; override;

    procedure AddParameter(const Name: String;
                           const Value: String = '');
    function  AsRouteHeader: TIdSipRouteHeader;
    function  AsString: String; override;
    function  CanonicaliseAsAddressOfRecord: String;
    procedure ClearHeaders;
    procedure ClearParameters;
    function  CreateRequest: TIdSipRequest;
    function  DefaultPort: Cardinal; virtual;
    function  DefaultTransport: String; virtual;
    function  Equals(Uri: TIdSipUri): Boolean;
    procedure EraseUserInfo;
    function  HasValidSyntax: Boolean;
    function  HasHeaders: Boolean;
    function  HasParameter(const Name: String): Boolean;
    function  IsLooseRoutable: Boolean;
    function  IsSecure: Boolean; virtual;
    function  IsSipUri: Boolean; override;
    function  ParamCount: Integer;
    function  ParamName(Index: Cardinal): String;
    function  ParamValue(Index: Cardinal): String; overload;
    function  ParamValue(const Name: String): String; overload;
    function  PortIsSpecified: Boolean;
    procedure RemoveParameter(const Name: String);
    function  TransportIsSpecified: Boolean;
    function  UserIsIp: Boolean;
    function  UserIsPhoneNumber: Boolean;

    property Headers:       TIdSipHeaders read fHeaders;
    property Host:          String        read fHost write fHost;
    property Maddr:         String        read GetMaddr write SetMaddr;
    property Method:        String        read GetMethod write SetMethod;
    property Password:      String        read fPassword write fPassword;
    property Port:          Cardinal      read fPort write SetPort;
    property Transport:     String        read GetTransport write SetTransport;
    property TTL:           Cardinal      read GetTTL write SetTTL;
    property Uri:           String        read GetUri write SetUri;
    property Username:      String        read fUsername write fUsername;
    property UserParameter: String        read GetUserParameter write SetUserParameter;
  end;

  // I represent a header in a SIP message.
  // Say I hold Contact information:
  //   '"Count Zero" <sip:countzero@jacksbar.com;paranoid>;very'.
  // The Value property will return everything except the parameters, i.e.,
  //   '"Count Zero" <sip:countzero@jacksbar.com;paranoid>'
  // ParamsAsString returns just my parameters, that is,
  //   ';very'.
  // FullValue will return absolutely everything, that is,
  //   '"Count Zero" <sip:countzero@jacksbar.com;paranoid>;very'
  // Lastly, AsString returns what will go down the wire, so to speak:
  //   'Contact: "Count Zero" <sip:countzero@jacksbar.com;paranoid>;very'
  TIdSipHeader = class(TPersistent)
  private
    fName:   String;
    fParams: TStrings;
    fValue:  String;

    function  GetParam(const Name: String): String;
    function  GetParameters: TStrings;
    procedure SetParam(const Name, Value: String);
    procedure SetParameters(Value: TStrings);

    property Parameters: TStrings read GetParameters write SetParameters;
  protected
    procedure FailParse;
    function  GetName: String; virtual;
    function  GetValue: String; virtual;
    procedure ParseParameters(Value: String;
                              Parameters: TStrings;
                              Delimiter: String = ';');
    procedure SetName(const Value: String); virtual;
    procedure SetValue(const Value: String); virtual;
  public
    class function EncodeQuotedStr(const S: String): String;
    constructor Create; virtual;
    destructor  Destroy; override;

    procedure Assign(Src: TPersistent); override;
    function  AsString: String;
    function  FullValue: String;
    function  HasParam(Name: String): Boolean;
    function  IndexOfParam(Name: String): Integer;
    function  IsContact: Boolean; virtual;
    function  Equals(Header: TIdSipHeader): Boolean; virtual;
    function  ParamCount: Integer;
    function  ParamsAsString: String; virtual;

    property Name:                       String read GetName write SetName;
    property Value:                      String read GetValue write SetValue;
    property Params[const Name: String]: String read GetParam write SetParam;
  end;

  TIdSipHeaderClass = class of TIdSipHeader;

  TIdSipUriHeader = class(TIdSipHeader)
  private
    fAddress: TIdSipUri;

    procedure SetAddress(Value: TIdSipUri);
  protected
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    constructor Create; override;
    destructor  Destroy; override;

    property Address: TIdSipUri read fAddress write SetAddress;
  end;

  TIdSipToHeader = class;

  TIdSipAddressHeader = class(TIdSipUriHeader)
  private
    fDisplayName: String;
  protected
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    function AsAddressOfRecord: String;
    function AsToHeader: TIdSipToHeader;
    function HasSipsUri: Boolean;

    property DisplayName: String read fDisplayName write fDisplayName;
  end;

  TIdSipHttpAuthHeader = class(TIdSipHeader)
  private
    fAuthorizationScheme: String;

    function  GetAlgorithm: String;
    function  GetNonce: String;
    function  GetOpaque: String;
    function  GetQop: String;
    function  GetRealm: String;
    function  GetUnknownResponses(const Name: String): String;
    procedure ParseDigestResponses(Value: String);
    procedure SetAlgorithm(const Value: String);
    procedure SetNonce(const Value: String);
    procedure SetOpaque(const Value: String);
    procedure SetQop(const Value: String);
    procedure SetRealm(const Value: String);
    procedure SetUnknownResponses(const Name: String;
                                  const Value: String);
  protected
    DigestResponses:      TStringList;
    fUnknownResponses:    TStringList;

    procedure CheckDigestResponses(Responses: TStrings); virtual;
    function  DigestResponseValue(const Name: String): String;
    function  GetValue: String; override;
    function  KnownResponse(const Name: String): Boolean; virtual;
    procedure SetValue(const Value: String); override;
  public
    class function IsNonce(const Token: String): Boolean;

    constructor Create; override;
    destructor  Destroy; override;

    property Algorithm:           String   read GetAlgorithm write SetAlgorithm;
    property AuthorizationScheme: String   read fAuthorizationScheme write fAuthorizationScheme;
    property Nonce:               String   read GetNonce write SetNonce;
    property Opaque:              String   read GetOpaque write SetOpaque;
    property Qop:                 String   read GetQop write SetQop;
    property Realm:               String   read GetRealm write SetRealm;
    property UnknownResponses[const Name: String]: String read GetUnknownResponses write SetUnknownResponses;
  end;

  TIdSipAuthorizationHeader = class(TIdSipHttpAuthHeader)
  private
    function  GetCNonce: String;
    function  GetDigestUri: String;
    function  GetNonceCount: Cardinal;
    function  GetResponse: String;
    function  GetUsername: String;
    procedure SetCNonce(const Value: String);
    procedure SetDigestUri(const Value: String);
    procedure SetNonceCount(Value: Cardinal);
    procedure SetResponse(const Value: String);
    procedure SetUsername(const Value: String);
  protected
    procedure CheckDigestResponses(Responses: TStrings); override;
    function  GetName: String; override;
    function  KnownResponse(const Name: String): Boolean; override;
  public
    function IsBasic: Boolean;
    function IsDigest: Boolean;

    property CNonce:     String   read GetCNonce write SetCNonce;
    property Response:   String   read GetResponse write SetResponse;
    property DigestUri:  String   read GetDigestUri write SetDigestUri; // This should be a TIdURI
    property NonceCount: Cardinal read GetNonceCount write SetNonceCount;
    property Username:   String   read GetUsername write SetUsername;
  end;


  TIdSipCallIdHeader = class(TIdSipHeader)
  protected
    function  GetName: String; override;
    procedure SetValue(const Value: String); override;
  public
    function Equals(Header: TIdSipHeader): Boolean; override;
  end;

  TIdSipCommaSeparatedHeader = class(TIdSipHeader)
  private
    fValues: TStrings;
  protected
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure RemoveValues(Header: TIdSipCommaSeparatedHeader);

    property Values: TStrings read fValues;
  end;

  TIdSipWeightedValue = class(TObject)
  private
    fParameters: TStrings;
    fValue:      String;
    fWeight:     TIdSipQValue;

    function GetParameters: TStrings;
  public
    destructor Destroy; override;

    function AsString: String;

    property Parameters: TStrings     read GetParameters;
    property Value:      String       read fValue write fValue;
    property Weight:     TIdSipQValue read fWeight write fWeight;
  end;

  TIdSipWeightedCommaSeparatedHeader = class(TIdSipHeader)
  private
    fValues: TObjectList;

    function  GetValues(Index: Integer): TIdSipWeightedValue;
    procedure SetValues(Index: Integer;
                        Value: TIdSipWeightedValue);
  protected
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    constructor Create; override;
    destructor  Destroy; override;

    procedure AddValue(const Value: String;
                       Weight: TIdSipQValue = High(TIdSipQValue));
    procedure ClearValues;
    function  ValueCount: Integer;

    property Values[Index: Integer]: TIdSipWeightedValue read GetValues write SetValues;
  end;

  TIdSipContactHeader = class(TIdSipAddressHeader)
  private
    fIsWildCard: Boolean;

    function  GetExpires: Cardinal;
    function  GetQ: TIdSipQValue;
    procedure SetExpires(Value: Cardinal);
    procedure SetQ(Value: TIdSipQValue);
  protected
    function  GetName: String; override;
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    procedure RemoveExpires;
    function  WillExpire: Boolean;

    property Expires:    Cardinal     read GetExpires write SetExpires;
    property IsWildCard: Boolean      read fIsWildCard write fIsWildCard;
    property Q:          TIdSipQValue read GetQ write SetQ;
  end;

  TIdSipContentDispositionHeader = class(TIdSipHeader)
  private
    function  GetHandling: String;
    procedure SetHandling(const Value: String);
  protected
    function GetName: String; override;
  public
    function IsSession: Boolean;
    property Handling: String read GetHandling write SetHandling;
  end;

  TIdSipCSeqHeader = class(TIdSipHeader)
  private
    fMethod:     String;
    fSequenceNo: Cardinal;
  protected
    function  GetName: String; override;
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    procedure Increment;

    property Method:     String   read fMethod     write fMethod;
    property SequenceNo: Cardinal read fSequenceNo write fSequenceNo;
  end;

  TIdSipDateHeader = class(TIdSipHeader)
  private
    fAbsoluteTime:   TIdDateTimeStamp;

    function  GetAbsoluteTime: TIdDateTimeStamp;
    procedure SetAbsoluteTime(Value: String);
  protected
    function  GetName: String; override;
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    destructor Destroy; override;

    function ZeroDateTime: String;

    property Time: TIdDateTimeStamp read GetAbsoluteTime;
  end;

  TIdSipFromToHeader = class(TIdSipAddressHeader)
  private
    function  GetTag: String;
    procedure SetTag(const Value: String);
  protected
    procedure SetValue(const Value: String); override;
  public
    function HasTag: Boolean;
    function Equals(Header: TIdSipHeader): Boolean; override;

    property Tag: String read GetTag write SetTag;
  end;

  TIdSipFromHeader = class(TIdSipFromToHeader)
  protected
    function GetName: String; override;
  end;

  TIdSipNumericHeader = class(TIdSipHeader)
  private
    fNumericValue: Cardinal;
  protected
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    property NumericValue: Cardinal read fNumericValue write fNumericValue;
  end;

  TIdSipMaxForwardsHeader = class(TIdSipNumericHeader)
  protected
    function  GetName: String; override;
    procedure SetValue(const Value: String); override;
  end;

  TIdSipProxyAuthenticateHeader = class(TIdSipHttpAuthHeader)
  private
    function  GetDomain: String;
    function  GetStale: Boolean;
    procedure SetDomain(const Value: String);
    procedure SetStale(const Value: Boolean);
  protected
    function GetName: String; override;
    function KnownResponse(const Name: String): Boolean; override;
  public
    procedure RemoveStaleResponse;

    property Domain: String  read GetDomain write SetDomain;
    property Stale:  Boolean read GetStale write SetStale;
  end;

  TIdSipAuthenticateInfoHeader = class(TIdSipHttpAuthHeader);

  TIdSipProxyAuthorizationHeader = class(TIdSipAuthorizationHeader)
  protected
    function GetName: String; override;
  end;

  TIdSipRouteHeader = class(TIdSipHeader)
  private
    fAddress:     TIdSipURI;
    fDisplayName: String;

    procedure SetAddress(Value: TIdSipURI);
  protected
    function  GetName: String; override;
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    constructor Create; override;
    destructor  Destroy; override;

    function EncodeQuotedStr(const S: String): String;
    function HasSipsUri: Boolean;
    function IsLooseRoutable: Boolean;

    property Address:     TIdSipURI read fAddress write SetAddress;
    property DisplayName: String    read fDisplayName write fDisplayName;
  end;

  TIdSipRecordRouteHeader = class(TIdSipRouteHeader)
  protected
    function GetName: String; override;
  end;

  TIdSipTimestamp = class(TObject)
  private
    fFractionalPart: Cardinal;
    fIntegerPart:    Cardinal;
  public
    property FractionalPart: Cardinal read fFractionalPart write fFractionalPart;
    property IntegerPart:    Cardinal read fIntegerPart write fIntegerPart;
  end;

  TIdSipTimestampHeader = class(TIdSipHeader)
  private
    fDelay:     TIdSipTimestamp;
    fTimestamp: TIdSipTimestamp;
  protected
    function  GetName: String; override;
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    constructor Create; override;
    destructor  Destroy; override;

    function NormalizeLWS(const S: String): String;
    function ReadNumber(var Src: String): Cardinal;

    property Delay:     TIdSipTimestamp read fDelay;
    property Timestamp: TIdSipTimestamp read fTimestamp;
  end;

  TIdSipToHeader = class(TIdSipFromToHeader)
  protected
    function GetName: String; override;
  end;

  TIdSipViaHeader = class(TIdSipHeader)
  private
    fSentBy:     String;
    fSipVersion: String;
    fPort:       Cardinal;
    fTransport:  TIdSipTransportType;

    procedure AssertBranchWellFormed;
    procedure AssertMaddrWellFormed;
    procedure AssertReceivedWellFormed;
    procedure AssertTTLWellFormed;
    function  GetBranch: String;
    function  GetMaddr: String;
    function  GetReceived: String;
    function  GetRport: Cardinal;
    function  GetTTL: Byte;
    procedure SetBranch(const Value: String);
    procedure SetMaddr(const Value: String);
    procedure SetReceived(const Value: String);
    procedure SetRport(Value: Cardinal);
    procedure SetTTL(Value: Byte);
  protected
    function  GetName: String; override;
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    procedure Assign(Src: TPersistent); override;
    function  DefaultPortForTransport(T: TIdSipTransportType): Cardinal;
    function  HasBranch: Boolean;
    function  HasMaddr: Boolean;
    function  HasReceived: Boolean;
    function  HasRport: Boolean;
    function  IsDefaultPortForTransport(Port: Cardinal;
                                        T: TIdSipTransportType): Boolean;
    function  IsRFC3261Branch: Boolean;

    property Branch:     String              read GetBranch write SetBranch;
    property SentBy:     String              read fSentBy write fSentBy;
    property Maddr:      String              read GetMaddr write SetMaddr;
    property Port:       Cardinal            read fPort write fPort;
    property Received:   String              read GetReceived write SetReceived;
    property Rport:      Cardinal            read GetRport write SetRport;
    property SipVersion: String              read fSipVersion write fSipVersion;
    property Transport:  TIdSipTransportType read fTransport write fTransport;
    property TTL:        Byte                read GetTTL write SetTTL;
  end;

  TIdSipWarningHeader = class(TIdSipHeader)
  private
    fAgent: String;
    fCode:  Cardinal;
    fText:  String;
  protected
    function  GetName: String; override;
    function  GetValue: String; override;
    procedure SetValue(const Value: String); override;
  public
    property Agent: String   read fAgent write fAgent;
    property Code:  Cardinal read fCode write fCode;
    property Text:  String   read fText write fText;
  end;

  TIdSipChallengeHeader = class(TIdSipHeader)
  end;

  // We sublass TIdSipProxyAuthenticateHeader purely for code re-use
  TIdSipWWWAuthenticateHeader = class(TIdSipProxyAuthenticateHeader)
  protected
    function GetName: String; override;
  end;

  TIdSipHeaderMap = class(TObject)
    fHeaderName:  String;
    fHeaderClass: TIdSipHeaderClass;
  public
    constructor Create(HeaderName: String; HeaderClass: TIdSipHeaderClass);

    property HeaderName:  String            read fHeaderName;
    property HeaderClass: TIdSipHeaderClass read fHeaderClass;
  end;

  // I represent a set of headers. I may or may not be ordered. That depends
  // on what sort've headers I contain. You may iterate over me using my
  // External Iterator methods.
  TIdSipHeaderList = class(TObject)
  protected
    class function HeaderTypes: TObjectList;
    class function IsHeader(const Header,
                            ExpectedHeaderName: String): Boolean;

    function ConstructHeader(HeaderName: String): TIdSipHeader;
    function GetItems(I: Integer): TIdSipHeader; virtual; abstract;
  public
    class function CanonicaliseName(HeaderName: String): String;
    class function GetHeaderName(Header: String): String;

    function  Add(const HeaderName: String): TIdSipHeader; overload; virtual; abstract;
    procedure Add(Header: TIdSipHeader); overload; virtual; abstract;
    procedure Add(Headers: TIdSipHeaderList); overload; virtual; abstract;
    function  AsString: String;
    procedure Clear; virtual; abstract;
    function  Count: Integer; virtual; abstract;
    function  CurrentHeader: TIdSipHeader; virtual; abstract;
    procedure First; virtual; abstract;
    function  HasEqualValues(const OtherHeaders: TIdSipHeaderList): Boolean;
    function  HasNext: Boolean; virtual; abstract;
    function  Equals(OtherHeaders: TIdSipHeaderList): Boolean;
    function  IsEmpty: Boolean;
    procedure Next; virtual; abstract;
    procedure Remove(Header: TIdSipHeader); virtual; abstract;

    property Items[I: Integer]: TIdSipHeader read GetItems;
  end;

  // I am a filter over an underlying set of headers. If you iterate over me
  // you will only find HeaderName headers. You can still add arbitrary
  // headers to me (i.e., to the set of headers I filter).
  TIdSipHeadersFilter = class(TIdSipHeaderList)
  private
    CurrentIndex: Integer;
    fHeaderName:  String;
    Headers:      TIdSipHeaders;

  protected
    function GetItems(Index: Integer): TIdSipHeader; override;
  public
    constructor Create(Headers: TIdSipHeaders;
                       const HeaderName: String);

    function  Add(const HeaderName: String): TIdSipHeader; overload; override;
    procedure Add(Header: TIdSipHeader); overload; override;
    procedure Add(Headers: TIdSipHeaderList); overload; override;
    procedure Clear; override;
    function  Count: Integer; override;
    function  CurrentHeader: TIdSipHeader; override;
    procedure First; override;
    function  HasNext: Boolean; override;
    procedure Next; override;
    procedure Remove(Header: TIdSipHeader); override;
    procedure RemoveAll;

    property HeaderName: String read fHeaderName;
  end;

  TIdSipHeaders = class(TIdSipHeaderList)
  private
    CurrentIndex: Integer;
    List:         TObjectList;

    function FindFirst(const HeaderName: String): TIdSipHeader;
    function GetHeaders(const Name: String): TIdSipHeader;
  protected
    function GetItems(I: Integer): TIdSipHeader; override;
  public
    class function IsCallID(const Header: String): Boolean;
    class function IsCompoundHeader(const Header: String): Boolean;
    class function IsContact(const Header: String): Boolean;
    class function IsContentLength(const Header: String): Boolean;
    class function IsCSeq(const Header: String): Boolean;
    class function IsErrorInfo(const Header: String): Boolean;
    class function IsFrom(const Header: String): Boolean;
    class function IsMaxForwards(const Header: String): Boolean;
    class function IsRecordRoute(const Header: String): Boolean;
    class function IsRoute(const Header: String): Boolean;
    class function IsTo(const Header: String): Boolean;
    class function IsVia(const Header: String): Boolean;
    class function IsWarning(const Header: String): Boolean;

    constructor Create; virtual;
    destructor  Destroy; override;

    function  Add(const HeaderName: String): TIdSipHeader; overload; override;
    procedure Add(Header: TIdSipHeader); overload; override;
    procedure Add(Headers: TIdSipHeaderList); overload; override;
    procedure AddInReverseOrder(Headers: TIdSipHeadersFilter);
    procedure Clear; override;
    function  CurrentHeader: TIdSipHeader; override;
    procedure Delete(I: Integer);
    function  Count: Integer; override;
    procedure First; override;
    function  GetAllButFirst: TIdSipHeaderList;
    function  HasHeader(const HeaderName: String): Boolean;
    function  HasNext: Boolean; override;
    procedure Next; override;
    procedure Remove(Header: TIdSipHeader); override;
    procedure RemoveAll(const HeaderName: String);

    // This returns the FIRST MATCHING header
    property Headers[const Name: String]: TIdSipHeader read GetHeaders; default;
  end;

  TIdSipContacts = class(TIdSipHeadersFilter)
  private
    BlankHeaders: TIdSipHeaders;
  public
    constructor Create(Headers: TIdSipHeaders); overload;
    constructor Create; overload;
    destructor  Destroy; override;

    function CurrentContact: TIdSipContactHeader;
  end;

  TIdSipExpiresHeaders = class(TIdSipHeadersFilter)
  public
    constructor Create(Headers: TIdSipHeaders);

    function CurrentExpires: Cardinal;
  end;

  TIdSipRecordRoutePath = class(TIdSipHeadersFilter)
  private
    BlankHeaders: TIdSipHeaders;
  public
    constructor Create(Headers: TIdSipHeaders); overload;
    constructor Create; overload;
    destructor  Destroy; override;

    function CurrentRecordRoute: TIdSipRecordRouteHeader;
  end;

  TIdSipRoutePath = class(TIdSipHeadersFilter)
  private
    BlankHeaders: TIdSipHeaders;
  public
    constructor Create(Headers: TIdSipHeaders); overload;
    constructor Create; overload;
    destructor  Destroy; override;

    procedure AddRoute(RouteUri: TIdSipUri);
    function  CurrentRoute: TIdSipRouteHeader;
    function  GetAllButFirst: TIdSipRoutePath;
  end;

  TIdSipViaPath = class(TIdSipHeadersFilter)
  public
    constructor Create(Headers: TIdSipHeaders);

    function  LastHop: TIdSipViaHeader;
    function  Length: Integer;
    procedure RemoveLastHop;
  end;

  EBadMessage = class;
  EBadMessageClass = class of EBadMessage;

  TIdSipMessage = class(TPersistent)
  private
    fBody:       String;
    fContacts:   TIdSipContacts;
    fPath:       TIdSipViaPath;
    fHeaders:    TIdSipHeaders;
    fSIPVersion: String;

    function  GetCallID: String;
    function  GetContentDisposition: TIdSipContentDispositionHeader;
    function  GetContentLanguage: String;
    function  GetContentLength: Cardinal;
    function  GetContentType: String;
    function  GetCSeq: TIdSipCSeqHeader;
    function  GetFrom: TIdSipFromHeader;
    function  GetTo: TIdSipToHeader;
    function  Minimum(A, B: Cardinal): Cardinal;
    function  QuickestContactExpiry: Cardinal;
    function  QuickestExpiresHeader: Cardinal;
    procedure SetCallID(const Value: String);
    procedure SetContacts(Value: TIdSipContacts);
    procedure SetContentDisposition(Value: TIdSipContentDispositionHeader);
    procedure SetContentLanguage(const Value: String);
    procedure SetContentLength(Value: Cardinal);
    procedure SetContentType(const Value: String);
    procedure SetCSeq(Value: TIdSipCSeqHeader);
    procedure SetFrom(Value: TIdSipFromHeader);
    procedure SetPath(Value: TIdSipViaPath);
    procedure SetTo(Value: TIdSipToHeader);
  protected
    function FirstLine: String; virtual; abstract;
    function MatchRequest(InitialRequest: TIdSipRequest): Boolean; virtual; abstract;
  public
    class function WillEstablishDialog(Request: TIdSipRequest;
                                       Response: TIdSipResponse): Boolean; overload;

    constructor Create; virtual;
    destructor  Destroy; override;

    procedure Accept(Visitor: IIdSipMessageVisitor); virtual;
    function  AddHeader(const HeaderName: String): TIdSipHeader; overload;
    procedure AddHeader(Header: TIdSipHeader); overload;
    procedure AddHeaders(Headers: TIdSipHeaderList);
    procedure Assign(Src: TPersistent); override;
    function  AsString: String;
    procedure ClearHeaders;
    function  ContactCount: Cardinal;
    function  Copy: TIdSipMessage;
    function  FirstContact: TIdSipContactHeader;
    function  FirstExpires: TIdSipNumericHeader;
    function  FirstHeader(const HeaderName: String): TIdSipHeader;
    function  FirstMinExpires: TIdSipNumericHeader;
    function  FirstRequire: TIdSipCommaSeparatedHeader;
    function  HasExpiry: Boolean;
    function  HasHeader(const HeaderName: String): Boolean;
    function  HeaderCount: Integer;
    function  QuickestExpiry: Cardinal;
    function  Equals(Msg: TIdSipMessage): Boolean; virtual; abstract;
    function  IsRequest: Boolean; virtual; abstract;
    function  LastHop: TIdSipViaHeader;
    function  MalformedException: EBadMessageClass; virtual; abstract;
    procedure ReadBody(Src: TStream);
    procedure RemoveHeader(Header: TIdSipHeader);
    procedure RemoveAllHeadersNamed(const Name: String);

    property Body:               String                         read fBody write fBody;
    property CallID:             String                         read GetCallID write SetCallID;
    property Contacts:           TIdSipContacts                 read fContacts write SetContacts;
    property ContentDisposition: TIdSipContentDispositionHeader read GetContentDisposition write SetContentDisposition;
    property ContentLanguage:    String                         read GetContentLanguage write SetContentLanguage;
    property ContentLength:      Cardinal                       read GetContentLength write SetContentLength;
    property ContentType:        String                         read GetContentType write SetContentType;
    property CSeq:               TIdSipCSeqHeader               read GetCSeq write SetCSeq;
    property From:               TIdSipFromHeader               read GetFrom write SetFrom;
    property Headers:            TIdSipHeaders                  read fHeaders;
    property Path:               TIdSipViaPath                  read fPath write SetPath;
    property SIPVersion:         String                         read fSIPVersion write fSIPVersion;
    property ToHeader:           TIdSipToHeader                 read GetTo write SetTo;
  end;

  TIdSipMessageClass = class of TIdSipMessage;

  TIdSipRequest = class(TIdSipMessage)
  private
    fMethod:      String;
    fRecordRoute: TIdSipRecordRoutePath;
    fRequestUri:  TIdSipURI;
    fRoute:       TIdSipRoutePath;

    function  GetMaxForwards: Byte;
    function  MatchSip1Request(InitialRequest: TIdSipRequest): Boolean;
    function  MatchSip2Request(InitialRequest: TIdSipRequest): Boolean;
    procedure SetMaxForwards(Value: Byte);
    procedure SetRecordRoute(Value: TIdSipRecordRoutePath);
    procedure SetRequestUri(Value: TIdSipURI);
    procedure SetRoute(Value: TIdSipRoutePath);
  protected
    function FirstLine: String; override;
    function MatchRequest(InitialRequest: TIdSipRequest): Boolean; override;
  public
    constructor Create; override;
    destructor  Destroy; override;

    procedure Accept(Visitor: IIdSipMessageVisitor); override;
    function  AckFor(Response: TIdSipResponse): TIdSipRequest;
    function  AddressOfRecord: String;
    procedure Assign(Src: TPersistent); override;
    function  CreateCancel: TIdSipRequest;
    function  DefaultMaxForwards: Cardinal;
    function  FirstAuthorization: TIdSipAuthorizationHeader;
    function  FirstProxyAuthorization: TIdSipProxyAuthorizationHeader;
    function  FirstProxyRequire: TIdSipCommaSeparatedHeader;
    function  HasAuthorization: Boolean;
    function  HasProxyAuthorization: Boolean;
    function  HasSipsUri: Boolean;
    function  IsAck: Boolean;
    function  IsBye: Boolean;
    function  IsCancel: Boolean;
    function  Equals(Msg: TIdSipMessage): Boolean; override;
    function  IsInvite: Boolean;
    function  IsRegister: Boolean;
    function  IsRequest: Boolean; override;
    function  MalformedException: EBadMessageClass; override;
    function  Match(Msg: TIdSipMessage): Boolean;
    function  RequiresResponse: Boolean;

    property MaxForwards: Byte                  read GetMaxForwards write SetMaxForwards;
    property Method:      String                read fMethod write fMethod;
    property RecordRoute: TIdSipRecordRoutePath read fRecordRoute write SetRecordRoute;
    property RequestUri:  TIdSipURI             read fRequestUri write SetRequestUri;
    property Route:       TIdSipRoutePath       read fRoute write SetRoute;
  end;

  TIdSipResponse = class(TIdSipMessage)
  private
    fStatusCode: Integer;
    fStatusText: String;

    procedure SetStatusCode(Value: Integer);
  protected
    function FirstLine: String; override;
    function MatchRequest(InitialRequest: TIdSipRequest): Boolean; override;
  public
    class function InResponseTo(Request: TIdSipRequest;
                                StatusCode: Cardinal): TIdSipResponse; overload;
    class function InResponseTo(Request: TIdSipRequest;
                                StatusCode: Cardinal;
                                Contact: TIdSipContactHeader): TIdSipResponse; overload;

    procedure Accept(Visitor: IIdSipMessageVisitor); override;
    procedure Assign(Src: TPersistent); override;
    function  Description: String;
    function  FirstProxyAuthenticate: TIdSipProxyAuthenticateHeader;
    function  FirstUnsupported: TIdSipCommaSeparatedHeader;
    function  FirstWWWAuthenticate: TIdSipWWWAuthenticateHeader;
    function  Equals(Msg: TIdSipMessage): Boolean; override;
    function  HasAuthenticationInfo: Boolean;
    function  HasProxyAuthenticate: Boolean;
    function  HasWWWAuthenticate: Boolean;
    function  IsFinal: Boolean;
    function  IsOK: Boolean;
    function  IsProvisional: Boolean;
    function  IsRequest: Boolean; override;
    function  IsTrying: Boolean;
    function  MalformedException: EBadMessageClass; override;
    function  WillEstablishDialog(Request: TIdSipRequest): Boolean; overload;

    property StatusCode: Integer read fStatusCode write SetStatusCode;
    property StatusText: String  read fStatusText write fStatusText;
  end;

  TIdSipParserError = procedure(const RawMessage, Reason: String) of object;

  {*
   * Some implementation principles we follow:
   *  * The original headers may be folded, may contain all manner of guff. We
   *    don't make any attempt to store the raw header - we parse it, and when
   *    we write out the headers we write them in the simplest possible way. As
   *    a result we CANNOT duplicate the exact form of the original message, even
   *    though the new message will be identical, semantically speaking.
   *  * We do (because we have to) keep the order of headers. We simple append
   *    any newly created headers.
   *  * We raise any and all parsing errors as exceptions that descend from
   *    EParser as soon as possible.
   *  * New headers can be created that the original message didn't have.
   *    These messages will, by default, have the empty string as value. For example,
   *    querying the value of Content-Type will create a TIdSipHeader with Value ''.
   *  * We regard each header as using a value from a particular grammar, and the
   *    header classes each contain parsers for that language (in the SetValue
   *    method).
   *  * We always separate comma-separated headers (that is, headers like Contact
   *    or Via) into separate headers. We do not do this for headers like Accept.
   *}
  TIdSipParser = class(TIdSimpleParser, IIdSipMessageVisitor)
  private
    fOnParserError: TIdSipParserError;

    procedure AddHeader(Msg: TIdSipMessage; Header: String);
    procedure CheckContentLengthContentType(Msg: TIdSipMessage);
    procedure CheckCSeqMethod(Request: TIdSipRequest);
    procedure CheckRequiredRequestHeaders(Msg: TIdSipMessage);
    procedure CheckRequiredResponseHeaders(Msg: TIdSipMessage);
    function  CreateResponseOrRequest(const Token: String): TIdSipMessage;
    procedure DoOnParseError(const Reason: String);
    procedure FailParse(Msg: TIdSipMessage;
                        const Reason: String);
    procedure InitializeMessage(Msg: TIdSipMessage);
    procedure ParseCompoundHeader(Msg: TIdSipMessage;
                                  const Header: String;
                                  Parms: String);
    procedure ParseHeader(Msg: TIdSipMessage; const Header: String);
    procedure ParseHeaders(Msg: TIdSipMessage);
    procedure ParseRequestLine(Request: TIdSipRequest);
    procedure ParseStatusLine(Response: TIdSipResponse);

    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    class function IsIPv6Reference(const Token: String): Boolean;
    class function IsMethod(Method: String): Boolean;
    class function IsQuotedString(const Token: String): Boolean;
    class function IsQValue(const Token: String): Boolean;
    class function IsScheme(const Scheme: String): Boolean;
    class function IsSipVersion(Version: String): Boolean;
    class function IsToken(const Token: String): Boolean;
    class function IsTransport(const Token: String): Boolean;
    class function IsWord(const Token: String): Boolean;

    function  GetHeaderName(Header: String): String;
    function  GetHeaderNumberValue(const Msg: TIdSipMessage;
                                   const Header: String): Cardinal;
    function  GetHeaderValue(Header: String): String;
    function  ParseAndMakeMessage: TIdSipMessage; overload;
    function  ParseAndMakeMessage(const Src: String): TIdSipMessage; overload;
    function  ParseAndMakeMessage(const Src: String;
                                  const MessageType: TIdSipMessageClass): TIdSipMessage; overload;
    function  ParseAndMakeRequest: TIdSipRequest; overload;
    function  ParseAndMakeRequest(const Src: String): TIdSipRequest; overload;
    function  ParseAndMakeResponse: TIdSipResponse; overload;
    function  ParseAndMakeResponse(const Src: String): TIdSipResponse; overload;
    procedure ParseMessage(const Msg: TIdSipMessage);
    procedure ParseRequest(const Request: TIdSipRequest);
    procedure ParseResponse(const Response: TIdSipResponse);

    procedure VisitRequest(Request: TIdSipRequest);
    procedure VisitResponse(Response: TIdSipResponse);

    property OnParserError: TIdSipParserError read fOnParserError write fOnParserError;
  end;

  EBadHeader = class(EParserError);
  EBadMessage = class(EParserError)
  private
    fRawMessage: String;
  public
    constructor Create(const Msg: String;
                       const RawMessage: String);
    property RawMessage: String read fRawMessage write fRawMessage;
  end;

  EBadRequest = class(EBadMessage);
  EBadResponse = class(EBadMessage);
  ESchemeNotSupported = class(Exception);

const
  HeaderUnreservedChars = ['[', ']', '/', '?', ':', '+', '$'];
  HeaderChars           = HeaderUnreservedChars + UnreservedChars;
  LegalTokenChars       = Alphabet + Digits
                        + ['-', '.', '!', '%', '*', '_',
                           '+', '`', '''', '~'];
  LegalWordChars        = LegalTokenChars
                        + ['(', ')', '<', '>', ':', '\', '"', '/', '[',
                           ']', '?', '{', '}'];
  LWSChars              = [' ', #9, #10, #13];
  ParamUnreservedChars  = ['[', ']', '/', ':', '&', '+', '$'];
  ParamChars            = ParamUnreservedChars + UnreservedChars;
  PasswordChars         = UnreservedChars + ['&', '=', '+', '$', ','];
  UserUnreservedChars   = ['&', '=', '+', '$', ',', ';', '?', '/'];
  UserChars             = Alphabet + Digits + UnreservedChars + UserUnreservedChars;

  BadStatusCode             = -1;
  ConvertErrorMsg           = 'Failed to convert ''%s'' to type %s';
  CSeqMethodMismatch        = 'CSeq header method doesn''t match request method';
  InvalidSipVersion         = 'Invalid Sip-Version: ''%s''';
  InvalidStatusCode         = 'Invalid Status-Code: ''%s''';
  MissingCallID             = 'Missing Call-ID header';
  MissingContentType        = 'Missing Content-Type header with a non-empty message-body';
  MissingCSeq               = 'Missing CSeq header';
  MissingFrom               = 'Missing From header';
  MissingMaxForwards        = 'Missing Max-Forwards header';
  MissingTo                 = 'Missing To header';
  MissingSipVersion         = 'Missing SIP-Version';
  MissingVia                = 'Missing Via header';
  RequestLine               = '%s %s %s' + EOL;
  RequestUriNoAngleBrackets = 'Request-URI may not be enclosed in <>';
  RequestUriNoSpaces        = 'Request-URI may not contain spaces';
  StatusLine                = '%s %d %s' + EOL;
  UnexpectedMessageLength   = 'Expected message-body length of %d but was %d';
  UnmatchedQuotes           = 'Unmatched quotes';

function DecodeQuotedStr(const S: String; var Dest: String): Boolean;
function EncodeQuotedStr(const S: String): String;
function FirstChar(const S: String): String;
function HalfQuoted(const S: String): Boolean;
function IsEqual(const S1, S2: String): Boolean;
function IsQuoted(const S: String): Boolean;
function LastChar(const S: String): String;
function NeedsQuotes(Name: String): Boolean;
function ParseNameAddr(NameAddr: String; var DisplayName, AddrSpec: String): Boolean;
function QuoteStringIfNecessary(const S: String): String;
function QValueToStr(const Q: TIdSipQValue): String;
function ShortMonthToInt(const Month: String): Integer;
function StreamToStr(Data: TStream): String;
function StrToQValue(const S: String): TIdSipQValue;
function StrToQValueDef(const S: String; const DefaultValue: TIdSipQValue): TIdSipQValue;
function StrToTransport(const S: String): TIdSipTransportType;
function TransportToStr(const T: TIdSipTransportType): String;
function WithoutFirstAndLastChars(const S: String): String;

implementation

uses
  IdRandom, IdSipConsts;

// class variables
var
  GCanonicalHeaderNames: TStrings;
  GIdSipHeadersMap:      TObjectList;

//******************************************************************************
//* Unit procedures & functions                                                *
//******************************************************************************
//* Unit private procedures & functions ****************************************

function DecodeQuotedStr(const S: String; var Dest: String): Boolean;
var
  I: Integer;
  FoundSlash: Boolean;
begin
  Result := true;

  // in summary:
  // '\' is illegal, '%s\' is illegal.

  Dest := S;

  if (Dest <> '') then begin
    if (Dest = '\') or (Dest = '"') then
      Result := false;

    if (Length(Dest) >= 2) and (Dest[Length(Dest)] = '\') and (Dest[Length(Dest) - 1] <> '\') then
      Result := Result and false;

    // We use "<" and not "<=" because if a \ is the last character we have
    // a malformed string. Too, this allows use to Dest[I + 1]
    I := 1;
    while (I < Length(Dest)) and Result do begin
      Result := Dest[I] <> '"';
      FoundSlash := Dest[I] = '\';
      if (FoundSlash) then begin
        Delete(Dest, I, 1);

        // protect '\\'
        if (FoundSlash) then begin
          Inc(I);
        end;
      end
      else
        Inc(I);
    end;
  end;
end;

function EncodeQuotedStr(const S: String): String;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do begin
    if (S[I] in ['\', '"']) then
      Result := Result + '\';

    Result := Result + S[I];
  end;
end;

function FirstChar(const S: String): String;
begin
  Result := Copy(S, 1, 1);
end;

function HalfQuoted(const S: String): Boolean;
begin
  Result := (FirstChar(S) = '"') xor (LastChar(S) = '"');
end;

function IsEqual(const S1, S2: String): Boolean;
begin
  Result := Lowercase(S1) = Lowercase(S2);
end;

function IsQuoted(const S: String): Boolean;
begin
  Result := (FirstChar(S) = '"') and (LastChar(S) = '"')
end;

function LastChar(const S: String): String;
begin
  Result := Copy(S, Length(S), 1);
end;

function NeedsQuotes(Name: String): Boolean;
var
  Token: String;
begin
  if (Name = '') then
    Result := false
  else begin
    Result := false;

    while (Name <> '') do begin
      Token := Fetch(Name, ' ');
      Result := Result or not TIdSipParser.IsToken(Token);
    end;
  end;
end;

function ParseNameAddr(NameAddr: String; var DisplayName, AddrSpec: String): Boolean;
var
  Name: String;
begin
  AddrSpec    := '';
  DisplayName := '';

  NameAddr := Trim(NameAddr);

  Result := IndyPos('<', NameAddr) > 0;

  if Result then begin
    if (NameAddr[1] = '"') then begin
      Name := Trim(Fetch(NameAddr, '<'));
      Delete(Name, 1, 1);

      Result := Result and (IndyPos('"', Name) <> 0);

      Name := Copy(Name, 1, RPos('"', Name, -1) - 1);

      // There was an encoded ", which MUST NOT match the opening "
      Result := Result and not ((Name <> '') and (Name[Length(Name)] = '\'));

      Result := Result and DecodeQuotedStr(Name, DisplayName);
    end else begin
      DisplayName := Trim(Fetch(NameAddr, '<'));

      Result := Result and not NeedsQuotes(DisplayName);
    end;

    AddrSpec := Trim(Fetch(NameAddr, '>'));
  end;
end;

function QuoteStringIfNecessary(const S: String): String;
begin
  Result := S;
  if NeedsQuotes(S) then
    Result := '"' + Result + '"'
end;

function QValueToStr(const Q: TIdSipQValue): String;
begin
  Result := IntToStr(Q div 1000);

  if (Q mod 1000 > 0) then begin
    Result := Result + '.';

    Result := Result + IntToStr(((Q mod 1000) div 100));
    Result := Result + IntToStr(((Q mod 100)  div 10));
    Result := Result + IntToStr(((Q mod 10)   div 1));

    while (Result[Length(Result)] = '0') do
      Delete(Result, Length(Result), 1);
  end;
end;

function ShortMonthToInt(const Month: String): Integer;
var
  Found: Boolean;
begin
  Found := false;
  for Result := Low(ShortMonthNames) to High(ShortMonthNames) do
    if IsEqual(ShortMonthNames[Result], Month) then begin
      Found := true;
      Break;
    end;

  if not Found then
    raise EConvertError.Create('Failed to convert ''' + Month + ''' to type Integer');
end;

function StreamToStr(Data: TStream): String;
var
  OriginalPosition: Int64;
  S:                TStringStream;
begin
  if not Assigned(Data) then begin
    Result := '';
    Exit;
  end;

  OriginalPosition := Data.Position;
  Data.Seek(0, soFromBeginning);
  try
    S := TStringStream.Create('');
    try
      S.CopyFrom(Data, 0);
      Result := S.DataString;
    finally
      S.Free;
    end;
  finally
    Data.Seek(OriginalPosition, soFromBeginning);
  end;
end;

function StrToQValue(const S: String): TIdSipQValue;
var
  Fraction, Int: String;
  Malformed:     Boolean;
  I:             Cardinal;
  E:             Integer;
  F:             Cardinal;
  Q:             Cardinal;
begin
  Q         := 0;
  F         := 0;
  Fraction  := S;
  Malformed := (Fraction = '') or (Pos(' ', S) > 0);

  if not Malformed then begin
    Malformed := (IndyPos('.', Fraction) > 0) and (Fraction[Length(Fraction)] = '.');

    Int := Fetch(Fraction, '.');

    Val(Int, I, E);
    Malformed := Malformed or (E <> 0) or (I > 1);

    Malformed := Malformed or (Length(Fraction) > 3);
    if (Fraction <> '') then begin
      while (Length(Fraction) < 3) do
        Fraction := Fraction + '0';

      Val(Fraction, F, E);
      Malformed := Malformed or (E <> 0) or (F > High(TIdSipQValue));
    end;

    Q := High(TIdSipQValue)*I + Trunc(F);
    Malformed := Malformed or (Q > High(TIdSipQValue));
  end;

  if Malformed then
    raise EConvertError.Create(Format(ConvertErrorMsg, [S, 'TIdSipQValue']));

  Assert(Q <= High(TIdSipQValue),
         'Sanity check assigning a Cardinal to a TIdSipQValue');
  Result := Q;
end;

function StrToQValueDef(const S: String; const DefaultValue: TIdSipQValue): TIdSipQValue;
begin
  try
    Result := StrToQValue(S);
  except
    on EConvertError do
      Result := DefaultValue;
  end;
end;

function StrToTransport(const S: String): TIdSipTransportType;
begin
       if (Lowercase(S) = 'null') then Result := sttNULL
  else if (Lowercase(S) = 'sctp') then Result := sttSCTP
  else if (Lowercase(S) = 'tcp')  then Result := sttTCP
  else if (Lowercase(S) = 'tls')  then Result := sttTLS
  else if (Lowercase(S) = 'udp')  then Result := sttUDP
  else raise EConvertError.Create(Format(ConvertErrorMsg, [S, 'TIdSipTransportType']));
end;

function TransportToStr(const T: TIdSipTransportType): String;
begin
  case T of
    sttNULL: Result := 'NULL';
    sttSCTP: Result := 'SCTP';
    sttTCP:  Result := 'TCP';
    sttTLS:  Result := 'TLS';
    sttUDP:  Result := 'UDP';
 else
    raise EConvertError.Create(Format(ConvertErrorMsg, ['unknown TIdSipTransportType', 'String']));
  end;
end;

function WithoutFirstAndLastChars(const S: String): String;
begin
  Result := Copy(S, 2, Length(S) - 2);
end;

//******************************************************************************
//* TIdUri                                                                     *
//******************************************************************************
//* TIdUri Public methods ******************************************************

function TIdUri.AsString: String;
begin
  Result := '';
end;

function TIdUri.IsSipUri: Boolean;
begin
  Result := (Lowercase(Self.Scheme) = SipScheme)
         or (Lowercase(Self.Scheme) = SipsScheme);
end;

//******************************************************************************
//* TIdSipUri                                                                  *
//******************************************************************************
//* TIdSipUri Public methods ***************************************************

class function TIdSipUri.CreateUri(URI: String = ''): TIdUri;
var
  Scheme: String;
begin
  Result := nil;
  try
    if (URI = '') then
      Result := TIdSipUri.Create(URI)
    else begin
      Scheme := Lowercase(Fetch(URI, ':', false));
      if (Scheme = SipScheme) or (Scheme = SipsScheme) then
        Result := TIdSipUri.Create(URI)
//      else if (Scheme = SipsScheme) then
//        Result := TIdSipsUri.Create(URI)
      else raise ESchemeNotSupported.Create(URI);
    end;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

class function TIdSipUri.Decode(const Src: String): String;
var
  CharCode: Integer;
  ESC:      String[2];
  I:        Integer;
begin
  Result := '';
  // S.G. 27/11/2002: Spaces is NOT to be encoded as "+".
  // S.G. 27/11/2002: "+" is a field separator in query parameter, space is...
  // S.G. 27/11/2002: well, a space

  I := 1;
  while I <= Length(Src) do begin
    if Src[I] <> '%' then begin
      Result := Result + Src[I];
      Inc(I);
    end
    else begin
      Inc(I); // skip the % char
      ESC := Copy(Src, I, 2); // Copy the escape code
      Inc(I, 2); // Then skip it.
      try
        CharCode := StrToInt('$' + ESC);
        if (CharCode > 0) and (CharCode < 256) then
          Result := Result + Char(CharCode);
      except
      end;
    end;
  end;
end;

class function TIdSipUri.Encode(const Src: String;
                                const SafeChars: TIdSipChars): String;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Src) do begin
    if Src[I] in SafeChars then
      Result := Result + Src[I]
    else
      Result := Result + '%' + IntToHex(Ord(Src[I]), 2);
  end;
end;

class function TIdSipUri.HeaderEncode(const NameOrValue: String): String;
begin
  Result := Self.Encode(NameOrValue, HeaderChars);
end;

class function TIdSipUri.IsParamNameOrValue(const Token: String): Boolean;
begin
  Result := Self.IsEscapedOrInSet(Token, ParamChars);
end;

class function TIdSipUri.IsPassword(const Token: String): Boolean;
begin
  Result := Self.IsEscapedOrInSet(Token, PasswordChars);
end;

class function TIdSipUri.IsUser(const Token: String): Boolean;
begin
  Result := Self.IsEscapedOrInSet(Token, UserChars);
end;

class function TIdSipUri.ParameterEncode(const Parameter: String): String;
begin
  Result := Self.Encode(Parameter, ParamChars);
end;

class function TIdSipUri.UsernameEncode(const Username: String): String;
begin
  Result := Self.Encode(Username, UserChars);
end;

constructor TIdSipUri.Create(URI: String = '');
begin
  inherited Create;

  Self.fHeaders   := TIdSipHeaders.Create;
  Self.Parameters := TStringList.Create;
  Self.Parse(Uri);
end;

destructor TIdSipUri.Destroy;
begin
  Self.Parameters.Free;
  Self.Headers.Free;

  inherited Destroy;
end;

procedure TIdSipUri.AddParameter(const Name: String;
                                 const Value: String = '');
begin
  Self.Parameters.Add(Name + '=' + Self.Decode(Value));
end;

function TIdSipUri.AsRouteHeader: TIdSipRouteHeader;
begin
  Result := TIdSipRouteHeader.Create;
  Result.Address := Self;
end;

function TIdSipUri.AsString: String;
begin
  Result := Self.Uri;
end;

function TIdSipUri.CanonicaliseAsAddressOfRecord: String;
var
  ResultUri: TIdSipUri;
begin
  ResultUri := TIdSipUri.Create(Self.Uri);
  try
    ResultUri.Password := '';
    ResultUri.Headers.Clear;
    ResultUri.Parameters.Clear;

    Result := TIdSipUri.Decode(ResultUri.Uri);
  finally
    ResultUri.Free;
  end;
end;

procedure TIdSipUri.ClearHeaders;
begin
  Self.Headers.Clear;
end;

procedure TIdSipUri.ClearParameters;
begin
  Self.Parameters.Clear;
end;

function TIdSipUri.CreateRequest: TIdSipRequest;
begin
  Result := TIdSipRequest.Create;
  Result.RequestUri := Self;

  if Result.RequestUri.HasParameter(MethodParam) then begin
    Result.Method := Result.RequestUri.ParamValue(MethodParam);
    Result.CSeq.Method := Result.Method;
    Result.RequestUri.RemoveParameter(MethodParam);
  end;

  Result.RequestUri.Headers.Clear;
end;

function TIdSipUri.DefaultPort: Cardinal;
begin
  if Self.IsSecure then
    Result := IdPORT_SIPS
  else
    Result := IdPORT_SIP;
end;

function TIdSipUri.DefaultTransport: String;
begin
  if Self.IsSecure then
    Result := TransportParamTLS
  else
    Result := TransportParamUDP;
end;

function TIdSipUri.Equals(Uri: TIdSipUri): Boolean;
begin
  // a SIP and SIPS URI are never equivalent
  Result := Lowercase(Self.Scheme) = Lowercase(Uri.Scheme);

  Result := Result
        and (Lowercase(Self.Host) = Lowercase(Uri.Host))
        and (Self.Port            = Uri.Port)
        and (Self.PortIsSpecified = Uri.PortIsSpecified)
        and (Self.Username        = Uri.Username)
        and (Self.Password        = Uri.Password)
        and Self.EqualParameters(Uri)
        and Self.Headers.Equals(Uri.Headers);
end;

procedure TIdSipUri.EraseUserInfo;
begin
  Self.Username := '';
  Self.Password := '';
end;

function TIdSipUri.HasValidSyntax: Boolean;
begin
  Result := Self.HasValidScheme
        and Self.HasValidHostInfo
        and Self.HasValidUserInfo
        and Self.HasValidParameters;

  if Self.IsSecure then
    Result := Result and (Self.Transport = TransportParamTLS);
end;

function TIdSipUri.HasHeaders: Boolean;
begin
  Result := not Self.Headers.IsEmpty;
end;

function TIdSipUri.HasParameter(const Name: String): Boolean;
begin
  Result := Self.Parameters.IndexOfName(Name) <> -1;
end;

function TIdSipUri.IsLooseRoutable: Boolean;
begin
  Result := Self.HasParameter(LooseRoutableParam);
end;

function TIdSipUri.IsSecure: Boolean;
begin
  Result := IsEqual(Self.Scheme, SipsScheme);
end;

function TIdSipUri.IsSipUri: Boolean;
begin
  Result := inherited IsSipUri;
end;

function TIdSipUri.ParamCount: Integer;
begin
  Result := Self.Parameters.Count;
end;

function TIdSipUri.ParamName(Index: Cardinal): String;
begin
  Result := Self.Parameters.Names[Index];
end;

function TIdSipUri.ParamValue(Index: Cardinal): String;
begin
  Result := Self.Parameters.Values[Self.ParamName(Index)];
end;

function TIdSipUri.ParamValue(const Name: String): String;
begin
  Result := Self.Parameters.Values[Name];
end;

function TIdSipUri.PortIsSpecified: Boolean;
begin
  Result := Self.fPortIsSpecified;
end;

procedure TIdSipUri.RemoveParameter(const Name: String);
begin
  if Self.HasParameter(Name) then
    Self.Parameters.Delete(Self.Parameters.IndexOfName(Name));
end;

function TIdSipUri.TransportIsSpecified: Boolean;
begin
  Result := Self.HasParameter(TransportParam);
end;

function TIdSipUri.UserIsIp: Boolean;
begin
  Result := IsEqual(Self.UserParameter, UserParamIp);
end;

function TIdSipUri.UserIsPhoneNumber: Boolean;
begin
  Result := IsEqual(Self.UserParameter, UserParamPhone);
end;

//* TIdSipUri Private methods **************************************************

class function TIdSipUri.IsEscapedOrInSet(const Token: String;
                                          AcceptableChars: TIdSipChars): Boolean;
var
  EndOfString: Integer;
  I:           Integer;
begin
  Result := Token <> '';

  if (Result) then begin
    EndOfString := Length(Token);
    I := 1;
    while (I <= EndOfString) and Result do begin
      if (Token[I] = '%') then begin
        Result := Result and ((EndOfString - I) >= 2)
                         and TIdSimpleParser.IsDigit(Token[I+1])
                         and TIdSimpleParser.IsDigit(Token[I+2]);
        Inc(I,2);
      end;

      Result := Result and (Token[I] in AcceptableChars);
      if not Result then Break;

      Inc(I);
    end;
  end;
end;

function TIdSipUri.EqualParameters(const Uri: TIdSipUri): Boolean;
begin
  Result := (Self.HasParameter(TransportParam) = Uri.HasParameter(TransportParam))
        and (Self.HasParameter(UserParam)      = Uri.HasParameter(UserParam))
        and (Self.HasParameter(TtlParam)       = Uri.HasParameter(TtlParam))
        and (Self.HasParameter(MethodParam)    = Uri.HasParameter(MethodParam))
        and (Self.HasParameter(MaddrParam)     = Uri.HasParameter(MaddrParam));

  // According to RFC 3261 section 19.1.4 if A and B are URIs then (apart
  // from special params - transport, ttl, etc) any parameters in both A.Params
  // and B.Params must have equal value. It's simple to compare one set against
  // another. Thus, we compare all the parameters in A.Params against those in
  // B.Params, and then vice versa.
  if Result then
    Result := Result
          and Self.UnidirectionalParameterCompare(Self, Uri)
          and Self.UnidirectionalParameterCompare(Uri, Self);
end;

function TIdSipUri.GetMaddr: String;
begin
  Result := Self.ParamValue(MaddrParam);
end;

function TIdSipUri.GetMethod: String;
begin
  Result := Self.ParamValue(MethodParam);
end;

function TIdSipUri.GetTransport: String;
begin
  Result := Self.ParamValue(TransportParam);

  if (Result = '') then
    Result := Self.DefaultTransport;
end;

function TIdSipUri.GetTTL: Cardinal;
begin
  Result := StrToInt(Self.ParamValue(TTLParam));
end;

function TIdSipUri.GetUri: String;
begin
  if (Self.Scheme = '') and (Self.Host = '') then
    Result := ''
  else begin
    Result := Self.Scheme + ':';

    if (Self.Username <> '') then begin
      Result := Result + Self.UsernameEncode(Self.Username);

      if (Self.Password <> '') then
        Result := Result + ':' + Self.Password;

      Result := Result + '@';
    end;

    Result := Result + Self.Host;

    if Self.Port <> Self.DefaultPort then
      Result := Result + ':' + IntToStr(Self.Port);

    Result := Result + Self.ParamsAsString + Self.HeadersAsString;
  end;
end;

function TIdSipUri.GetUserParameter: String;
begin
  Result := Self.ParamValue(UserParam);
end;

function TIdSipUri.HasValidHostInfo: Boolean;
begin
  Result := TIdSimpleParser.IsFQDN(Self.Host)
         or TIdIPAddressParser.IsIPv4Address(Self.Host)
         or TIdIPAddressParser.IsIPv6Address(Self.Host);
end;

function TIdSipUri.HasValidParameters: Boolean;
var
  I: Integer;
begin
  Result := true;
  for I := 0 to Self.ParamCount - 1 do begin
    Result := Result and Self.IsParamNameOrValue(Self.ParamName(I))
                     and Self.IsParamNameOrValue(Self.ParamValue(I));

    if not Result then Break;
  end;
end;

function TIdSipUri.HasValidScheme: Boolean;
begin
  Result := (Self.Scheme = SipScheme) or (Self.Scheme = SipsScheme);
end;

function TIdSipUri.HasValidUserInfo: Boolean;
begin
  Result := ((Self.Username = '') or Self.IsUser(Self.Username))
        and ((Self.Password = '') or Self.IsPassword(Self.Password))
end;

function TIdSipUri.HeadersAsString: String;
var
  HeaderName:  String;
  HeaderValue: String;
begin
  Result := '';

  if not Self.Headers.IsEmpty then begin
    Self.Headers.First;
    while Self.Headers.HasNext do begin
      HeaderValue := Self.Headers.CurrentHeader.AsString;
      HeaderName  := Trim(Fetch(HeaderValue, ':'));
      HeaderValue := Trim(HeaderValue);

      Result := Result
              + TIdSipUri.HeaderEncode(HeaderName) + '='
              + TIdSipUri.HeaderEncode(HeaderValue) + '&';

      Self.Headers.Next;
    end;

    Result := '?' + Copy(Result, 1, Length(Result) - 1);
  end;
end;

function TIdSipUri.IsKnownParameter(const Name: String): Boolean;
var
  CaselessName: String;
begin
  CaselessName := Lowercase(Name);
  Result := (CaselessName = UserParam)
         or (CaselessName = TtlParam)
         or (CaselessName = MethodParam)
         or (CaselessName = MaddrParam)
end;

function TIdSipUri.ParamsAsString: String;
var
  I:     Integer;
  Param: String;
begin
  Result := '';

  for I := 0 to Self.Parameters.Count - 1 do begin
    Param := Self.ParamName(I);
    if (Self.ParamValue(I) <> '') then
      Param := Param + '=' + TIdSipUri.ParameterEncode(Self.ParamValue(I));

    Result := Result + ';' + Param;
  end;
end;

procedure TIdSipUri.Parse(Uri: String);
begin
  Self.Reset;

  if (Uri <> '') then begin
    Self.Scheme := Fetch(Uri, ':');
    if (IndyPos('@', Uri) > 0) then
      Self.ParseUserInfo(Fetch(Uri, '@'));

    if (IndyPos(';', Uri) > 0) then begin
      Self.ParseHost(Fetch(Uri, ';'));
      Self.ParseParams(Fetch(Uri, '?'));

      if (Uri <> '') then
        Self.ParseHeaders(Uri);
    end
    else begin
      if (IndyPos('?', Uri) > 0) then begin
        Self.ParseHost(Fetch(Uri, '?'));
        Self.ParseHeaders(Uri);
      end
      else
        Self.ParseHost(Uri);
    end;
  end;
end;

procedure TIdSipUri.ParseHeaders(HeaderList: String);
var
  HeaderName:  String;
  HeaderValue: String;
begin
  while (HeaderList <> '') do begin
    HeaderValue := Fetch(HeaderList, '&');
    HeaderName := Fetch(HeaderValue, '=');

    Self.Headers.Add(HeaderName).Value := TIdSipURI.Decode(HeaderValue);
  end;
end;

procedure TIdSipUri.ParseHost(HostAndPort: String);
begin
  Self.Host := Fetch(HostAndPort, ':');

  if (HostAndPort = '') then begin
    if Self.IsSecure then
      Self.Port := IdPORT_SIPS
    else
      Self.Port := IdPORT_SIP;
    Self.fPortIsSpecified := false;
  end
  else
    Self.Port := StrToIntDef(HostAndPort, IdPORT_SIP);
end;

procedure TIdSipUri.ParseParams(ParamList: String);
var
  ParamName:  String;
  ParamValue: String;
begin
  while (ParamList <> '') do begin
    ParamValue := Fetch(ParamList, ';');
    ParamName := Fetch(ParamValue, '=');

    Self.AddParameter(ParamName, ParamValue);
  end;
end;

procedure TIdSipUri.ParseUserInfo(UserInfo: String);
begin
  Self.Username := TIdSipURI.Decode(Fetch(UserInfo, ':'));
  Self.Password := UserInfo;
end;

procedure TIdSipUri.Reset;
begin
  Self.Headers.Clear;
  Self.Host      := '';
  Self.Parameters.Clear;
  Self.Password  := '';
  Self.Port      := Self.DefaultPort;
  Self.Scheme    := '';
  Self.Username  := '';
end;

procedure TIdSipUri.SetMaddr(const Value: String);
begin
  Self.Parameters.Values[MaddrParam] := Value;
end;

procedure TIdSipUri.SetMethod(const Value: String);
begin
  Self.Parameters.Values[MethodParam] := Value;
end;

procedure TIdSipUri.SetPort(const Value: Cardinal);
begin
  Self.fPort            := Value;
  Self.fPortIsSpecified := true;
end;

procedure TIdSipUri.SetTransport(const Value: String);
begin
  Self.Parameters.Values[TransportParam] := Value;
end;

procedure TIdSipUri.SetTTL(const Value: Cardinal);
begin
  Self.Parameters.Values[TTLParam] := IntToStr(Value);
end;

procedure TIdSipUri.SetUri(const Value: String);
begin
  Self.Parse(Value);
end;

procedure TIdSipUri.SetUserParameter(const Value: String);
begin
  Self.Parameters.Values[UserParam] := Value;
end;

function TIdSipUri.UnidirectionalParameterCompare(ThisUri, ThatUri: TIdSipUri): Boolean;
var
  I: Integer;
  OurName: String;
begin
  Result := true;

  for I := 0 to ThisUri.ParamCount - 1 do begin
    OurName := ThisUri.ParamName(I);

    if ThisUri.IsKnownParameter(OurName) then begin
      Result := Result
            and ThatUri.HasParameter(OurName)
            and (ThisUri.ParamValue(OurName) = ThatUri.ParamValue(OurName));
    end
    else begin
      if ThatUri.HasParameter(OurName) then
        Result := Result
              and (ThisUri.ParamValue(OurName) = ThatUri.ParamValue(OurName));
    end;
  end;
end;

//******************************************************************************
//* TIdSipHeader                                                               *
//******************************************************************************
//* TIdSipHeader Public methods ************************************************

class function TIdSipHeader.EncodeQuotedStr(const S: String): String;
begin
  Result := StringReplace(S,      '\', '\\', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll, rfIgnoreCase]);
end;

constructor TIdSipHeader.Create;
begin
  // This has no functional meaning. It just makes inspecting variables a bit
  // more sane for the developer. For instance, TIdSipViaHeader.fName will have
  // the value 'Via', even though a TIdSipViaHeader's fName cannot be read
  // because TIdSipViaHeader overrides GetName.
  Self.Name := Self.GetName;
end;

destructor TIdSipHeader.Destroy;
begin
  fParams.Free;

  inherited Destroy;
end;

procedure TIdSipHeader.Assign(Src: TPersistent);
var
  H: TIdSipHeader;
begin
  if Src is TIdSipHeader then begin
    H := Src as TIdSipHeader;
    Self.Name       := H.Name;
    Self.Value      := H.Value;
    Self.Parameters := H.Parameters;
  end
  else inherited Assign(Src);
end;

function TIdSipHeader.AsString: String;
begin
  Result := Self.Name + ': ' + Self.FullValue;
end;

function TIdSipHeader.FullValue: String;
begin
  Result := Self.Value + Self.ParamsAsString;
end;

function TIdSipHeader.HasParam(Name: String): Boolean;
begin
  Result := Self.IndexOfParam(Name) <> -1;
end;

function TIdSipHeader.IndexOfParam(Name: String): Integer;
var
  Found:      Boolean;
  ParamValue: String;
  ParamName:  String;
begin
  Name := Trim(Name);

  Result := 0;
  Found  := false;
  while (Result < Self.Parameters.Count) and not Found do begin
    ParamValue := Self.Parameters[Result];
    ParamName := Fetch(ParamValue, '=');
    Found := IsEqual(Name, ParamName);
    if not Found then
      Inc(Result);
  end;

  if (Result = Self.Parameters.Count) then
    Result := -1;
end;

function TIdSipHeader.IsContact: Boolean;
begin
  Result := TIdSipHeaders.IsContact(Self.Name);
end;

function TIdSipHeader.Equals(Header: TIdSipHeader): Boolean;
begin
  Result := IsEqual(Self.AsString, Header.AsString);
end;

function TIdSipHeader.ParamCount: Integer;
begin
  if not Assigned(fParams) then
    Result := 0
  else
    Result := Self.Parameters.Count;
end;

function TIdSipHeader.ParamsAsString: String;
var
  I:          Integer;
  ParamName:  String;
  ParamValue: String;
begin
  Result := '';
  for I := 0 to Self.ParamCount - 1 do begin
    ParamValue := Self.Parameters[I];
    ParamName  := Fetch(ParamValue, '=');

    Result := Result + ';' + ParamName;

    ParamValue := QuoteStringIfNecessary(EncodeQuotedStr(ParamValue));

    if (ParamValue <> '') then
      Result := Result + '=' + ParamValue;
  end;
end;

//* TIdSipHeader Protected methods *********************************************

procedure TIdSipHeader.FailParse;
begin
  raise EBadHeader.Create(Self.Name);
end;

function TIdSipHeader.GetName: String;
begin
  Result := fName;
end;

function TIdSipHeader.GetValue: String;
begin
  Result := fValue;
end;

procedure TIdSipHeader.ParseParameters(Value: String; Parameters: TStrings; Delimiter: String = ';');
var
  ParamName:  String;
  ParamValue: String;
  RealValue:  String;
begin
  Parameters.Clear;
  Fetch(Value, ';');

  while (Value <> '') do begin
    ParamValue := Fetch(Value, Delimiter);
    ParamName  := Fetch(ParamValue, '=');

    ParamName  := Trim(ParamName);
    ParamValue := Trim(ParamValue);

    if (ParamValue = '') then
      Parameters.Add(ParamName)
    else begin
      if IsQuoted(ParamValue) then begin
        if not DecodeQuotedStr(WithoutFirstAndLastChars(ParamValue), RealValue) then
          Self.FailParse;
        Parameters.Add(ParamName + '=' + RealValue)
      end
      else
        Parameters.Add(ParamName + '=' + ParamValue);
    end;
  end;
end;

procedure TIdSipHeader.SetName(const Value: String);
begin
  fName := Value;
end;

procedure TIdSipHeader.SetValue(const Value: String);
var
  S: String;
begin
  S := Value;

  if (IndyPos(';', S) = 0) then
    fValue := S
  else
    fValue := Trim(Fetch(S, ';', false));

  Self.ParseParameters(S, Self.Parameters);
end;

//* TIdSipHeader Private methods ***********************************************

function TIdSipHeader.GetParam(const Name: String): String;
var
  I: Integer;
begin
  I := Self.IndexOfParam(Name);

  if (I > -1) then begin
    Result := Self.Parameters[I];
    Fetch(Result, '=');
    Result := Trim(Result)
  end
  else
    Result := '';
end;

function TIdSipHeader.GetParameters: TStrings;
begin
  if not Assigned(fParams) then
    fParams := TStringList.Create;

  Result := fParams;
end;

procedure TIdSipHeader.SetParam(const Name, Value: String);
var
  I: Integer;
begin
  I := Self.IndexOfParam(Name);


  if (I = -1) then
    Self.Parameters.Add(Trim(Name) + '=' + Value)
  else
    Self.Parameters[I] := Trim(Name) + '=' + Value;
end;

procedure TIdSipHeader.SetParameters(Value: TStrings);
begin
  Self.Parameters.Assign(Value);
end;

//******************************************************************************
//* TIdSipUriHeader                                                            *
//******************************************************************************
//* TIdSipUriHeader Public methods *********************************************

constructor TIdSipUriHeader.Create;
begin
  inherited Create;

  fAddress := TIdSipUri.Create('');
end;

destructor TIdSipUriHeader.Destroy;
begin
  fAddress.Free;

  inherited Destroy;
end;

function TIdSipUriHeader.GetValue: String;
begin
  Result := Self.Address.URI;

  if   (IndyPos(';', Result) > 0)
    or (IndyPos(',', Result) > 0)
    or (IndyPos('?', Result) > 0)
    or (Result <> '') then
    Result := '<' + Result + '>';
end;

procedure TIdSipUriHeader.SetValue(const Value: String);
var
  AddrSpec:    String;
  DisplayName: String;
  S:           String;
begin
  Self.Address.URI := '';

  S := Trim(Value);
  if (IndyPos('<', Value) = 0) then
    Self.FailParse;

  if not ParseNameAddr(Value, DisplayName, AddrSpec) then
    Self.FailParse;
  if (DisplayName <> '') then
    Self.FailParse;

  Self.Address.URI := AddrSpec;
  Fetch(S, '>');

  inherited SetValue(S);
end;

//* TIdSipUriHeader Private methods ********************************************

procedure TIdSipUriHeader.SetAddress(Value: TIdSipUri);
begin
  fAddress.URI := Value.URI;
end;

//******************************************************************************
//* TIdSipAddressHeader                                                        *
//******************************************************************************
//* TIdSipAddressHeader Public methods *****************************************

function TIdSipAddressHeader.AsAddressOfRecord: String;
begin
  Result := Self.Address.CanonicaliseAsAddressOfRecord;
end;

function TIdSipAddressHeader.AsToHeader: TIdSipToHeader;
begin
  Result := TIdSipToHeader.Create;
  Result.Value := Self.FullValue
end;

function TIdSipAddressHeader.HasSipsUri: Boolean;
begin
  Result := Self.Address.IsSecure;
end;

//* TIdSipAddressHeader Protected methods **************************************

function TIdSipAddressHeader.GetValue: String;
var
  URI: String;
begin
  Result := Self.DisplayName;
  if (IndyPos('"', Result) > 0) or (IndyPos('\', Result) > 0) then
    Result := Self.EncodeQuotedStr(Result);

  Result := QuoteStringIfNecessary(Result);

  URI := Self.Address.URI;
  if (IndyPos(';', URI) > 0) or (IndyPos(',', URI) > 0) or (IndyPos('?', URI) > 0) or (Result <> '') then
    URI := '<' + URI + '>';

  if (Result = '') then
    Result := URI
  else
    Result := Result + ' ' + URI;
end;

procedure TIdSipAddressHeader.SetValue(const Value: String);
var
  AddrSpec:    String;
  DisplayName: String;
  S:           String;
begin
  Self.DisplayName := '';
  Self.Address.URI := '';

  S := Trim(Value);
  if (IndyPos('<', S) > 0) then begin
    if not ParseNameAddr(S, DisplayName, AddrSpec) then
      Self.FailParse;

    Self.Address.URI := AddrSpec;

    Fetch(S, '>');
    Self.ParseParameters(S, Self.Parameters);
  end
  else begin
    // Any semicolons in a URI not in angle brackets indicate that the
    // HEADER has the parameters, not the URI. Hence we separate the
    // parameters first to prevent the TIdSipUri from adding those
    // parameters to itself.
    Self.Address.URI := Trim(Fetch(S, ';'));

    if (S <> '') then
      S := ';' + S;

    Self.ParseParameters(S, Self.Parameters);
  end;

  if (Self.Address.Uri <> '')
    and not Self.Address.IsSipUri then
    Self.FailParse;

  Self.DisplayName := DisplayName;
end;

//******************************************************************************
//* TIdSipHttpAuthHeader                                                       *
//******************************************************************************
//* TIdSipHttpAuthHeader Public methods ****************************************

class function TIdSipHttpAuthHeader.IsNonce(const Token: String): Boolean;
var
  Unused: String;
begin
  Result := DecodeQuotedStr(Token, Unused);
end;

constructor TIdSipHttpAuthHeader.Create;
begin
  inherited Create;

  Self.DigestResponses   := TStringList.Create;
  Self.fUnknownResponses := TStringList.Create;
end;

destructor TIdSipHttpAuthHeader.Destroy;
begin
  Self.fUnknownResponses.Free;
  Self.DigestResponses.Free;

  inherited Destroy;
end;

//* TIdSipHttpAuthHeader Protected methods *************************************

procedure TIdSipHttpAuthHeader.CheckDigestResponses(Responses: TStrings);
begin
end;

function TIdSipHttpAuthHeader.DigestResponseValue(const Name: String): String;
begin
  if (Self.DigestResponses.IndexOfName(Name) = -1) then
    Result := ''
  else
    Result := Self.DigestResponses.Values[Name]
end;

function TIdSipHttpAuthHeader.GetValue: String;
var
  I:     Integer;
  Name:  String;
  Value: String;
begin
  Result := Self.AuthorizationScheme + ' ';

  for I := 0 to Self.DigestResponses.Count - 1 do begin
    Name  := Self.DigestResponses.Names[I];
    Value := Self.DigestResponses.Values[Name];

    Result := Result + Name
            + '="' + EncodeQuotedStr(Value) + '",';
  end;

  for I := 0 to Self.fUnknownResponses.Count - 1 do begin
    Name  := Self.fUnknownResponses.Names[I];
    Value := Self.fUnknownResponses.Values[Name];

    Result := Result + Name
            + '="' + EncodeQuotedStr(Value) + '",';
  end;

  if (LastChar(Result) = ',') then
    Result := Copy(Result, 1, Length(Result) - 1);
end;

function TIdSipHttpAuthHeader.KnownResponse(const Name: String): Boolean;
begin
  Result := (Name = AlgorithmParam)
         or (Name = NonceParam)
         or (Name = OpaqueParam)
         or (Name = QopParam)
         or (Name = RealmParam)
         or (Name = UsernameParam);
end;

procedure TIdSipHttpAuthHeader.SetValue(const Value: String);
var
  S: String;

begin
  inherited SetValue(Value);

  S := Value;
  Self.AuthorizationScheme := Fetch(S, ' ');

  Self.ParseDigestResponses(S);
  Self.CheckDigestResponses(Self.DigestResponses);
end;

//* TIdSipHttpAuthHeader Private methods ***************************************

function TIdSipHttpAuthHeader.GetAlgorithm: String;
begin
  Result := Self.DigestResponseValue(AlgorithmParam);
end;

function TIdSipHttpAuthHeader.GetNonce: String;
begin
  Result := Self.DigestResponseValue(NonceParam);
end;

function TIdSipHttpAuthHeader.GetOpaque: String;
begin
  Result := Self.DigestResponseValue(OpaqueParam);
end;

function TIdSipHttpAuthHeader.GetQop: String;
begin
  Result := Self.DigestResponseValue(QopParam);
end;

function TIdSipHttpAuthHeader.GetRealm: String;
begin
  Result := Self.DigestResponseValue(RealmParam);
end;

function TIdSipHttpAuthHeader.GetUnknownResponses(const Name: String): String;
begin
  if (Self.fUnknownResponses.IndexOfName(Name) = -1) then
    Result := ''
  else
    Result := Self.fUnknownResponses.Values[Name]
end;

procedure TIdSipHttpAuthHeader.ParseDigestResponses(Value: String);
var
  DecodedValue:  String;
  ResponseName:  String;
  ResponseValue: String;
begin
  Self.DigestResponses.Clear;

  while (Value <> '') do begin
    ResponseValue := Fetch(Value, ',');
    ResponseName := Trim(Fetch(ResponseValue, '='));

    if IsQuoted(ResponseValue) then begin
      if not DecodeQuotedStr(WithoutFirstAndLastChars(ResponseValue), DecodedValue) then
        Self.FailParse;
    end
    else if HalfQuoted(ResponseValue) then
      Self.FailParse
    else
      DecodedValue := ResponseValue;

    if Self.KnownResponse(ResponseName) then
      Self.DigestResponses.Add(ResponseName + '=' + DecodedValue)
    else
      Self.fUnknownResponses.Add(ResponseName + '=' + DecodedValue);
  end;
end;

procedure TIdSipHttpAuthHeader.SetAlgorithm(const Value: String);
begin
  Self.DigestResponses.Values[AlgorithmParam] := Value;
end;

procedure TIdSipHttpAuthHeader.SetNonce(const Value: String);
begin
  Self.DigestResponses.Values[NonceParam] := Value;
end;

procedure TIdSipHttpAuthHeader.SetOpaque(const Value: String);
begin
  Self.DigestResponses.Values[OpaqueParam] := Value;
end;

procedure TIdSipHttpAuthHeader.SetQop(const Value: String);
begin
  Self.DigestResponses.Values[QopParam] := Value;
end;

procedure TIdSipHttpAuthHeader.SetRealm(const Value: String);
begin
  Self.DigestResponses.Values[RealmParam] := Value;
end;

procedure TIdSipHttpAuthHeader.SetUnknownResponses(const Name: String;
                                                        const Value: String);
begin
  Self.fUnknownResponses.Values[Name] := Value;
end;

//******************************************************************************
//* TIdSipAuthorizationHeader                                                  *
//******************************************************************************
//* TIdSipAuthorizationHeader Public methods ***********************************

function TIdSipAuthorizationHeader.IsBasic: Boolean;
begin
  Result := IsEqual(Self.AuthorizationScheme, BasicAuthorizationScheme);
end;

function TIdSipAuthorizationHeader.IsDigest: Boolean;
begin
  Result := IsEqual(Self.AuthorizationScheme, DigestAuthorizationScheme);
end;

//* TIdSipAuthorizationHeader Protected methods ********************************

procedure TIdSipAuthorizationHeader.CheckDigestResponses(Responses: TStrings);
begin
  inherited CheckDigestResponses(Responses);

  if (Self.Response <> '')
    and not TIdSimpleParser.IsHexNumber(Self.Response) then
    Self.FailParse;
end;

function TIdSipAuthorizationHeader.GetName: String;
begin
  Result := AuthorizationHeader;
end;

//* TIdSipAuthorizationHeader Private methods **********************************

function TIdSipAuthorizationHeader.GetCNonce: String;
begin
  Result := Self.DigestResponseValue(CNonceParam);
end;

function TIdSipAuthorizationHeader.GetDigestUri: String;
begin
  Result := Self.DigestResponseValue(DigestUriParam);
end;

function TIdSipAuthorizationHeader.GetNonceCount: Cardinal;
begin
  Result := HexToInt(Self.DigestResponseValue(NonceCountParam));
end;

function TIdSipAuthorizationHeader.GetResponse: String;
begin
  Result := Self.DigestResponseValue(DigestResponseParam);
end;

function TIdSipAuthorizationHeader.GetUsername: String;
begin
  Result := Self.DigestResponseValue(UsernameParam);
end;

function TIdSipAuthorizationHeader.KnownResponse(const Name: String): Boolean;
begin
  Result := inherited KnownResponse(Name)
         or (Name = CNonceParam)
         or (Name = DigestResponseParam)
         or (Name = DigestUriParam)
         or (Name = NonceCountParam)
         or (Name = UsernameParam);
end;

procedure TIdSipAuthorizationHeader.SetCNonce(const Value: String);
begin
  Self.DigestResponses.Values[CNonceParam] := Value;
end;

procedure TIdSipAuthorizationHeader.SetDigestUri(const Value: String);
begin
  Self.DigestResponses.Values[DigestUriParam] := Value;
end;

procedure TIdSipAuthorizationHeader.SetNonceCount(Value: Cardinal);
var
  H: String;
begin
  H := IntToHex(Value, 8);

  // Strip off leading zeroes, but leave '0' unchanged
  while (Length(H) > 1) and (H[1] = '0') do
    Delete(H, 1, 1);

  Self.DigestResponses.Values[NonceCountParam] := H;
end;

procedure TIdSipAuthorizationHeader.SetResponse(const Value: String);
begin
  Self.DigestResponses.Values[DigestResponseParam] := Value;
end;

procedure TIdSipAuthorizationHeader.SetUsername(const Value: String);
begin
  Self.DigestResponses.Values[UsernameParam] := Value;
end;

//******************************************************************************
//* TIdSipCallIdHeader                                                         *
//******************************************************************************
//* TIdSipCallIdHeader Public methods ******************************************

function TIdSipCallIdHeader.Equals(Header: TIdSipHeader): Boolean;
begin
  Result := IsEqual(Header.Name, Self.Name)
        and (Self.Value = Header.Value);
end;

//* TIdSipCallIdHeader Protected methods ***************************************

function TIdSipCallIdHeader.GetName: String;
begin
  Result := CallIDHeaderFull;
end;

procedure TIdSipCallIdHeader.SetValue(const Value: String);
var
  Val: String;
  Token: String;
begin
  if (IndyPos('@', Value) > 0) then begin
    Val := Value;
    Token := Fetch(Val, '@');
    if not TIdSipParser.IsWord(Val) or not TIdSipParser.IsWord(Token) then
      Self.FailParse;
  end
  else if not TIdSipParser.IsWord(Value) then
    Self.FailParse;

  inherited SetValue(Value);
end;

//******************************************************************************
//* TIdSipCommaSeparatedHeader                                                 *
//******************************************************************************
//* TIdSipCommaSeparatedHeader Public methods **********************************

constructor TIdSipCommaSeparatedHeader.Create;
begin
  inherited Create;

  fValues := TStringList.Create;
end;

destructor TIdSipCommaSeparatedHeader.Destroy;
begin
  fValues.Free;

  inherited Destroy;
end;

procedure TIdSipCommaSeparatedHeader.RemoveValues(Header: TIdSipCommaSeparatedHeader);
var
  I: Integer;
begin
  // TODO: Find a better way to do this than Schlemiel the Painter!
  for I := 0 to Header.Values.Count - 1 do
    Self.Values.Delete(Self.Values.IndexOf(Header.Values[I]));
end;

//* TIdSipCommaSeparatedHeader Protected methods *******************************

function TIdSipCommaSeparatedHeader.GetValue: String;
var
  I: Integer;
begin
  Result := '';

  for I := 0 to Self.Values.Count - 2 do
    Result := Result + Self.Values[I] + ', ';

  if (Self.Values.Count > 0) then
    Result := Result + Self.Values[Self.Values.Count - 1];
end;

procedure TIdSipCommaSeparatedHeader.SetValue(const Value: String);
var
  S: String;
begin
  S := Value;

  Self.Values.Clear;

  while (S <> '') do begin
    Self.Values.Add(Trim(Fetch(S, ',')));
  end;
end;

//******************************************************************************
//* TIdSipWeightedValue                                                        *
//******************************************************************************
//* TIdSipWeightedValue Public methods *****************************************

destructor TIdSipWeightedValue.Destroy;
begin
  fParameters.Free;

  inherited Destroy;
end;

function TIdSipWeightedValue.AsString: String;
var
  I: Integer;
begin
  Result := Self.Value;

  if (Self.Weight < High(TIdSipQValue)) then
    Result := Result + ';q=' + QValueToStr(Self.Weight);

  for I := 0 to Self.Parameters.Count - 1 do
    Result := Result + ';' + Self.Parameters[I];
end;

//* TIdSipWeightedValue Private methods ****************************************

function TIdSipWeightedValue.GetParameters: TStrings;
begin
  if not Assigned(fParameters) then
    fParameters := TStringList.Create;

  Result := fParameters;
end;

//******************************************************************************
//* TIdSipWeightedCommaSeparatedHeader                                         *
//******************************************************************************
//* TIdSipWeightedCommaSeparatedHeader Public methods **************************

constructor TIdSipWeightedCommaSeparatedHeader.Create;
begin
  inherited Create;

  fValues := TObjectList.Create(true);
end;

destructor TIdSipWeightedCommaSeparatedHeader.Destroy;
begin
  fValues.Free;

  inherited Destroy;
end;

procedure TIdSipWeightedCommaSeparatedHeader.AddValue(const Value: String;
                                                      Weight: TIdSipQValue = High(TIdSipQValue));
var
  NewValue: TIdSipWeightedValue;
  OldCount: Integer;
begin
  OldCount := Self.ValueCount;
  NewValue := TIdSipWeightedValue.Create;
  try
    NewValue.Value := Value;
    NewValue.Weight := Weight;

    fValues.Add(NewValue);
  except
    if (Self.ValueCount = OldCount) then
      NewValue.Free;
  end;
end;

procedure TIdSipWeightedCommaSeparatedHeader.ClearValues;
begin
  fValues.Clear;
end;

function TIdSipWeightedCommaSeparatedHeader.ValueCount: Integer;
begin
  Result := fValues.Count;
end;

//* TIdSipWeightedCommaSeparatedHeader Protected methods ***********************

function TIdSipWeightedCommaSeparatedHeader.GetValue: String;
var
  I: Integer;
begin
  Result := '';

  for I := 0 to Self.ValueCount - 1 do begin
    Result := Result + Self.Values[I].AsString + ', ';
  end;

  Delete(Result, Length(Result) - 1, 2);
end;

procedure TIdSipWeightedCommaSeparatedHeader.SetValue(const Value: String);
var
  S:          String;
  MediaRange: String;
  Params:     String;
  NewParams:  TStrings;
  QValue:     String;
begin
  Self.ClearValues;

  S := Value;

  while (S <> '') do begin
    MediaRange := Trim(Fetch(S, ','));

    if (IndyPos(';', MediaRange) > 0) then begin
      Params := MediaRange;
      MediaRange := Fetch(Params, ';', false);
    end
    else
      Params := '';

    NewParams := TStringList.Create;
    try
      Self.ParseParameters(Params, NewParams);

      QValue := NewParams.Values[Qparam];

      if (QValue <> '')
        and not TIdSipParser.IsQValue(QValue) then
        Self.FailParse;
      Self.AddValue(MediaRange, StrToQValueDef(QValue, High(TIdSipQValue)));

      if (NewParams.IndexOfName(QParam) <> -1) then
        NewParams.Delete(NewParams.IndexOfName(QParam));

      Self.Values[Self.ValueCount - 1].Parameters.AddStrings(NewParams);
    finally
      NewParams.Free;
    end;
  end;
end;

//* TIdSipWeightedCommaSeparatedHeader Private methods *************************

function TIdSipWeightedCommaSeparatedHeader.GetValues(Index: Integer): TIdSipWeightedValue;
begin
  Result := fValues[Index] as TIdSipWeightedValue;
end;

procedure TIdSipWeightedCommaSeparatedHeader.SetValues(Index: Integer;
                                                       Value: TIdSipWeightedValue);
begin
  (fValues[Index] as TIdSipWeightedValue).Value  := Value.Value;
  (fValues[Index] as TIdSipWeightedValue).Weight := Value.Weight;
end;

//******************************************************************************
//* TIdSipContactHeader                                                        *
//******************************************************************************
//* TIdSipContactHeader Public methods *****************************************

procedure TIdSipContactHeader.RemoveExpires;
begin
  if Self.HasParam(ExpiresParam) then
    Self.Parameters.Delete(Self.Parameters.IndexOfName(ExpiresParam));
end;

function TIdSipContactHeader.WillExpire: Boolean;
begin
  Result := Self.HasParam(ExpiresParam);
end;

//* TIdSipContactHeader Protected methods **************************************

function TIdSipContactHeader.GetName: String;
begin
  Result := ContactHeaderFull;
end;

function TIdSipContactHeader.GetValue: String;
begin
  if Self.IsWildCard then
    Result := ContactWildCard
  else
    Result := inherited GetValue;
end;

procedure TIdSipContactHeader.SetValue(const Value: String);
var
  S: String;
begin
  S := Value;
  Self.IsWildCard := Fetch(S, ';') = ContactWildCard;

  if Self.IsWildCard then
    Self.ParseParameters(Value, Self.Parameters)
  else
    inherited SetValue(Value);

  if (Self.IndexOfParam(QParam) > -1) and not TIdSipParser.IsQValue(Self.Params[QParam]) then
    Self.FailParse;
  if (Self.IndexOfParam(ExpiresParam) > -1) and not TIdSipParser.IsNumber(Self.Params[ExpiresParam]) then
    Self.FailParse;
end;

//* TIdSipContactHeader Private methods ****************************************

function TIdSipContactHeader.GetExpires: Cardinal;
begin
  Result := StrToInt(Self.Params[ExpiresParam]);
end;

function TIdSipContactHeader.GetQ: TIdSipQValue;
begin
  Result := StrToQValue(Self.Params[QParam]);
end;

procedure TIdSipContactHeader.SetExpires(Value: Cardinal);
begin
  Self.Params[ExpiresParam] := IntToStr(Value);
end;

procedure TIdSipContactHeader.SetQ(Value: TIdSipQValue);
begin
  Self.Params[QParam] := QValueToStr(Value);
end;

//******************************************************************************
//* TIdSipContentDispositionHeader                                             *
//******************************************************************************
//* TIdSipContentDispositionHeader Public methods ******************************

function TIdSipContentDispositionHeader.IsSession: Boolean;
begin
  Result := IsEqual(Self.Handling, DispositionSession);
end;

//* TIdSipContentDispositionHeader Protected methods ***************************

function TIdSipContentDispositionHeader.GetName: String;
begin
  Result := ContentDispositionHeader;
end;

//* TIdSipContentDispositionHeader Private methods *****************************

function TIdSipContentDispositionHeader.GetHandling: String;
begin
  Result := Self.Params[HandlingParam];
end;

procedure TIdSipContentDispositionHeader.SetHandling(const Value: String);
begin
  Self.Params[HandlingParam] := Value;
end;

//******************************************************************************
//* TIdSipCSeqHeader                                                           *
//******************************************************************************
//* TIdSipCSeqHeader Public methods ********************************************

procedure TIdSipCSeqHeader.Increment;
begin
  if (Self.SequenceNo < High(Self.SequenceNo)) then
    Self.SequenceNo := Self.SequenceNo + 1
  else
    Self.SequenceNo := 0;
end;

//* TIdSipCSeqHeader Protected methods *****************************************

function TIdSipCSeqHeader.GetName: String;
begin
  Result := CSeqHeader;
end;

function TIdSipCSeqHeader.GetValue: String;
begin
  Result := IntToStr(Self.SequenceNo) + ' ' + Self.Method;
end;

procedure TIdSipCSeqHeader.SetValue(const Value: String);
var
  S:     String;
  Token: String;
  E:     Integer;
  N:     Cardinal;
begin
  S := Trim(Value);
  // Yes, sure, there will be no spaces returned from Fetch(S, ' '). But what
  // about other kinds of whitespace? Best to be sure!
  Token := Trim(Fetch(S, ' '));

  Val(Token, N, E);
  if (E <> 0) then
    Self.FailParse;

  Self.SequenceNo := N;

  Token := Trim(S);
  if not TIdSipParser.IsMethod(Token) then
    Self.FailParse;

    Self.Method := Token;
end;

//******************************************************************************
//* TIdSipDateHeader                                                           *
//******************************************************************************
//* TIdSipDateHeader Public methods ********************************************

destructor TIdSipDateHeader.Destroy;
begin
  fAbsoluteTime.Free;

  inherited Destroy;
end;

function TIdSipDateHeader.ZeroDateTime: String;
begin
  Result := '30 Dec 1899 00:00:00 GMT';
end;

//* TIdSipDateHeader Protected methods *****************************************

function TIdSipDateHeader.GetName: String;
begin
  Result := DateHeader;
end;

function TIdSipDateHeader.GetValue: String;
begin
//  Result := inherited GetValue;
  Result := Self.Time.GetAsRFC822;
end;

procedure TIdSipDateHeader.SetValue(const Value: String);
begin
  inherited SetValue(Value);

  Self.SetAbsoluteTime(Value);
end;

//* TIdSipDateHeader Private methods *******************************************

function TIdSipDateHeader.GetAbsoluteTime: TIdDateTimeStamp;
begin
  if not Assigned(fAbsoluteTime) then
    fAbsoluteTime := TIdDateTimeStamp.Create(nil);

  Result := fAbsoluteTime;
end;

procedure TIdSipDateHeader.SetAbsoluteTime(Value: String);
begin
  // We cannot differentiate between a malformed date (which returns a zero)
  // and the date Self.ZeroTime
  Self.Time.SetFromRFC822(Value);

  // Therefore we try inspect the string manually. Yes, this method can be
  // fooled - "00:00:00 GMT hahahahahaha 1899-30Dec" will not raise a parse
  // error.
  if ((IndyPos('Dec', Value) = 0)
      or (IndyPos('30', Value) = 0)
      or (IndyPos('1899', Value) = 0)
      or (IndyPos('00:00:00 GMT', Value) = 0))
    and (Self.Time.AsTDateTime = 0) then
    Self.FailParse;
end;

//******************************************************************************
//* TIdSipFromToHeader                                                         *
//******************************************************************************
//* TIdSipFromToHeader Public methods ******************************************

function TIdSipFromToHeader.HasTag: Boolean;
begin
  Result := Self.IndexOfParam(TagParam) <> -1;
end;

function TIdSipFromToHeader.Equals(Header: TIdSipHeader): Boolean;
var
  From: TIdSipFromToHeader;
begin
  Result := Header is TIdSipFromToHeader;

  if Result then begin
    From := Header as TIdSipFromToHeader;

    Result := (Self.Name = Header.Name)
          and (Self.Address.URI = From.Address.URI)
          and (Self.Tag = From.Tag);
  end;
end;

//* TIdSipFromToHeader Protected methods ***************************************

procedure TIdSipFromToHeader.SetValue(const Value: String);
begin
  inherited SetValue(Value);

  if (Self.IndexOfParam(TagParam) > -1)
    and not TIdSipParser.IsToken(Self.Params[TagParam]) then
    Self.FailParse;
end;

//* TIdSipFromToHeader Private methods *****************************************

function TIdSipFromToHeader.GetTag: String;
begin
  Result := Self.Params[TagParam];
end;

procedure TIdSipFromToHeader.SetTag(const Value: String);

begin
  if (Value = '') then begin
    if Self.HasTag then
      Self.Parameters.Delete(Self.IndexOfParam(TagParam))
  end
  else begin
    Self.Params[TagParam] := Value;

    if Self.HasTag and not TIdSipParser.IsToken(Self.Params[TagParam]) then
      Self.FailParse;
  end;
end;

//******************************************************************************
//* TIdSipFromHeader                                                           *
//******************************************************************************
//* TIdSipFromHeader Protected methods *****************************************

function TIdSipFromHeader.GetName: String;
begin
  Result := FromHeaderFull;
end;

//******************************************************************************
//* TIdSipMaxForwardsHeader                                                    *
//******************************************************************************
//* TIdSipMaxForwardsHeader Protected methods **********************************

function TIdSipMaxForwardsHeader.GetName: String;
begin
  Result := MaxForwardsHeader;
end;

procedure TIdSipMaxForwardsHeader.SetValue(const Value: String);
var
  N: Cardinal;
  E: Integer;
begin
  Val(Value, N, E);

  if (E <> 0) or (N > 255) then
    Self.FailParse;

  inherited SetValue(Value);
end;

//******************************************************************************
//* TIdSipProxyAuthenticateHeader                                              *
//******************************************************************************
//* TIdSipProxyAuthenticateHeader Protected methods ****************************

function TIdSipProxyAuthenticateHeader.GetName: String;
begin
  Result := ProxyAuthenticateHeader;
end;

function TIdSipProxyAuthenticateHeader.KnownResponse(const Name: String): Boolean;
begin
  Result := inherited KnownResponse(Name)
         or (Name = DomainParam)
         or (Name = StaleParam);
end;

procedure TIdSipProxyAuthenticateHeader.RemoveStaleResponse;
var
  Index: Integer;
begin
  Index := Self.DigestResponses.IndexOfName(StaleParam);

  if (Index <> -1) then
    Self.DigestResponses.Delete(Index);
end;

//* TIdSipProxyAuthenticateHeader Private methods ******************************

function TIdSipProxyAuthenticateHeader.GetDomain: String;
begin
  Result := Self.DigestResponseValue(DomainParam);
end;

function TIdSipProxyAuthenticateHeader.GetStale: Boolean;
begin
  Result := StrToBoolDef(Self.DigestResponseValue(StaleParam), false);
end;

procedure TIdSipProxyAuthenticateHeader.SetDomain(const Value: String);
begin
  Self.DigestResponses.Values[DomainParam] := Value;
end;

procedure TIdSipProxyAuthenticateHeader.SetStale(const Value: Boolean);
begin
    Self.DigestResponses.Values[StaleParam] := Lowercase(BoolToStr(Value));
end;

//******************************************************************************
//* TIdSipProxyAuthorizationHeader                                             *
//******************************************************************************
//* TIdSipProxyAuthorizationHeader Protected methods ***************************

function TIdSipProxyAuthorizationHeader.GetName: String;
begin
  Result := ProxyAuthorizationHeader;
end;

//******************************************************************************
//* TIdSipNumericHeader                                                        *
//******************************************************************************
//* TIdSipNumericHeader Protected methods **************************************

function TIdSipNumericHeader.GetValue: String;
begin
  Result := IntToStr(fNumericValue);
end;

procedure TIdSipNumericHeader.SetValue(const Value: String);
begin
  if not TIdSipParser.IsNumber(Value) then
    Self.FailParse
  else begin
    fNumericValue := StrToInt(Value);

    inherited SetValue(Value);
  end;
end;

//******************************************************************************
//* TIdSipRouteHeader                                                          *
//******************************************************************************
//* TIdSipRouteHeader Public methods *******************************************

constructor TIdSipRouteHeader.Create;
begin
  inherited Create;

  fAddress := TIdSipURI.Create('');
end;

destructor TIdSipRouteHeader.Destroy;
begin
  fAddress.Free;

  inherited Destroy;
end;

function TIdSipRouteHeader.EncodeQuotedStr(const S: String): String;
begin
  Result := S;
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll, rfIgnoreCase]);
end;

function TIdSipRouteHeader.HasSipsUri: Boolean;
begin
  Result := Self.Address.Scheme = SipsScheme;
end;

function TIdSipRouteHeader.IsLooseRoutable: Boolean;
begin
  Result := Pos(LooseRoutableParam, Self.Address.URI) > 0;
end;

//* TIdSipRouteHeader Protected methods ****************************************

function TIdSipRouteHeader.GetName: String;
begin
  Result := RouteHeader;
end;

function TIdSipRouteHeader.GetValue: String;
var
  URI: String;
begin
  Result := Self.DisplayName;
  if (IndyPos('"', Result) > 0) or (IndyPos('\', Result) > 0) then
    Result := Self.EncodeQuotedStr(Result);

  Result := QuoteStringIfNecessary(Result);

  URI := '<' + Self.Address.URI + '>';

  if (Result = '') then
    Result := URI
  else
    Result := Result + ' ' + URI;
end;

procedure TIdSipRouteHeader.SetValue(const Value: String);
var
  AddrSpec:     String;
  DisplayName:  String;
  HeaderParams: String;
begin
  if not ParseNameAddr(Value, DisplayName, AddrSpec) then
    Self.FailParse;

  if (IndyPos(':', AddrSpec) = 0) then
    Self.FailParse;

  Self.Address.URI := AddrSpec;
  Self.DisplayName := DisplayName;

  // cull the processed name-addr (and its parameters!)
  HeaderParams := Value;
  Fetch(HeaderParams, '>');

  inherited SetValue(HeaderParams);
end;

//* TIdSipRouteHeader Private methods ******************************************

procedure TIdSipRouteHeader.SetAddress(Value: TIdSipURI);
begin
  fAddress.URI := Value.URI;
end;

//******************************************************************************
//* TIdSipRecordRouteHeader                                                    *
//******************************************************************************
//* TIdSipRecordRouteHeader Protected methods **********************************

function TIdSipRecordRouteHeader.GetName: String;
begin
  Result := RecordRouteHeader;
end;

//******************************************************************************
//* TIdSipTimestampHeader                                                      *
//******************************************************************************
//* TIdSipTimestampHeader Public methods ***************************************

constructor TIdSipTimestampHeader.Create;
begin
  inherited Create;

  fDelay     := TIdSipTimestamp.Create;
  fTimestamp := TIdSipTimestamp.Create;
end;

destructor TIdSipTimestampHeader.Destroy;
begin
  Self.Timestamp.Free;
  Self.Delay.Free;

  inherited Destroy;
end;

function TIdSipTimestampHeader.NormalizeLWS(const S: String): String;
var
  I: Integer;
begin
  Result := S;

  I := 1;
  while (I <= Length(Result)) do begin
    if (Result[I] in LWSChars) then begin
      Result[I] := ' ';
      Inc(I);

      while (Result[I] in LWSChars) do
        Delete(Result, I, 1);
    end;
    Inc(I);
  end;
end;

function TIdSipTimestampHeader.ReadNumber(var Src: String): Cardinal;
var
  I: Integer;
  Number: String;
begin
  if (Src = '') then Self.FailParse;

  I := 1;
  while (I <= Length(Src)) and (Src[I] in Digits) do Inc(I);


  Number := Copy(Src, 1, I - 1);
  if not TIdSipParser.IsNumber(Number) then Self.FailParse;

  Result := StrToInt(Number);
  Delete(Src, 1, I - 1);
end;

//* TIdSipTimestampHeader Protected methods ************************************

function TIdSipTimestampHeader.GetName: String;
begin
  Result := TimestampHeader;
end;

function TIdSipTimestampHeader.GetValue: String;
begin
  Result := IntToStr(Self.Timestamp.IntegerPart);

  if (Self.Timestamp.FractionalPart <> 0) then
    Result := Result + IntToStr(Self.Timestamp.FractionalPart);
end;

procedure TIdSipTimestampHeader.SetValue(const Value: String);
var
  S: String;
begin
  Self.Delay.FractionalPart     := 0;
  Self.Delay.IntegerPart        := 0;
  Self.Timestamp.FractionalPart := 0;
  Self.Timestamp.IntegerPart    := 0;

  S := Self.NormalizeLWS(Value);

  Self.Timestamp.IntegerPart := Self.ReadNumber(S);
  if (S <> '') then begin
    if (S[1] <> '.') then Self.FailParse;
    Delete(S, 1, 1);

    if (S <> '') then
      Self.Timestamp.FractionalPart := Self.ReadNumber(S);
  end;

  if (S <> '') then begin
    if (S[1] <> ' ') then Self.FailParse;
    Delete(S, 1, 1);

    if (S[1] = '.') then
      Self.Delay.IntegerPart := 0
    else
      Self.Delay.IntegerPart := Self.ReadNumber(S);
  end;

  if (S <> '') then begin
    if (S[1] <> '.') then Self.FailParse;
    Delete(S, 1, 1);

    Self.Delay.FractionalPart := Self.ReadNumber(S);
  end;
end;

//******************************************************************************
//* TIdSipToHeader                                                             *
//******************************************************************************
//* TIdSipToHeader Protected methods *******************************************

function TIdSipToHeader.GetName: String;
begin
  Result := ToHeaderFull;
end;

//******************************************************************************
//* TIdSipViaHeader                                                            *
//******************************************************************************
//* TIdSipViaHeader Public methods *********************************************

procedure TIdSipViaHeader.Assign(Src: TPersistent);
var
  V: TIdSipViaHeader;
begin
  if (Src is TIdSipViaHeader) then begin
    V := Src as TIdSipViaHeader;

    // Yes, we're referencing private variables directly. We do this so we
    // avoid the parse checking that the setters normally do. For instance,
    // a blank or RFC 2543 style branch is invalid in RFC 3261, but we still
    // need to be able to work with the (malformed) Via.
    fSentBy     := V.SentBy;
    fSipVersion := V.SipVersion;
    fPort       := V.Port;
    fTransport  := V.Transport;

    // And we use the usual way of setting everything else.
    Self.Parameters := V.Parameters;
  end
  else
    inherited Assign(Src);
end;

function TIdSipViaHeader.DefaultPortForTransport(T: TIdSipTransportType): Cardinal;
begin
  if (T = sttTLS) then
    Result := IdPort_SIPS
  else
    Result := IdPORT_SIP;
end;

function TIdSipViaHeader.HasBranch: Boolean;
begin
  Result := Self.Branch <> '';
end;

function TIdSipViaHeader.HasMaddr: Boolean;
begin
  Result := Self.Maddr <> '';
end;

function TIdSipViaHeader.HasReceived: Boolean;
begin
  Result := Self.Received <> '';
end;

function TIdSipViaHeader.HasRport: Boolean;
begin
  Result := Self.HasParam(RPortParam);
end;

function TIdSipViaHeader.IsDefaultPortForTransport(Port: Cardinal;
                                                   T: TIdSipTransportType): Boolean;
begin
  Result := ((T = sttTLS) and (Port = IdPORT_SIPS))
         or (Port = IdPORT_SIP);
end;

function TIdSipViaHeader.IsRFC3261Branch: Boolean;
begin
  Result := Copy(Self.Branch, 1, Length(BranchMagicCookie)) = BranchMagicCookie;
end;

//* TIdSipViaHeader Protected methods ******************************************

function TIdSipViaHeader.GetName: String;
begin
  Result := ViaHeaderFull;
end;

function TIdSipViaHeader.GetValue: String;
begin
  Result := Self.SipVersion + '/' + TransportToStr(Self.Transport)
          + ' ' + Self.SentBy;

  if not Self.IsDefaultPortForTransport(Self.Port, Self.Transport) then
    Result := Result + ':' + IntToStr(Self.Port);
end;

procedure TIdSipViaHeader.SetValue(const Value: String);
var
  Token: String;
  S:     String;
begin
  inherited SetValue(Value);

  Self.AssertBranchWellFormed;
  Self.AssertReceivedWellFormed;
  Self.AssertMaddrWellFormed;
  Self.AssertTTLWellFormed;

  S := Value;
  S := Fetch(S, ';', false);

  Token := Trim(Fetch(S, '/')) + '/';
  Token := Token + Trim(Fetch(S, '/'));
  Self.SipVersion := Token;

  S := Trim(S);
  Token := Trim(Fetch(S, ' '));
  if not TIdSipParser.IsTransport(Token) then
    Self.FailParse;

  Self.Transport := StrToTransport(Token);

  Token := Trim(Fetch(S, ';'));
  Self.SentBy := Fetch(Token, ':');

  if (Token = '') then
    Self.Port := Self.DefaultPortForTransport(Self.Transport)
  else
    Self.Port := StrToInt(Token);
end;

//* TIdSipViaHeader Private methods ********************************************

procedure TIdSipViaHeader.AssertBranchWellFormed;
begin
  if (Self.IndexOfParam(BranchParam) > -1)
     and not TIdSipParser.IsToken(Self.Params[BranchParam]) then
    Self.FailParse;
end;

procedure TIdSipViaHeader.AssertMaddrWellFormed;
begin
  if (Self.Parameters.IndexOfName(MaddrParam) > -1) then begin
    if    not TIdSipParser.IsFQDN(Self.Parameters.Values[MaddrParam])
      and not TIdIPAddressParser.IsIPv4Address(Self.Parameters.Values[MaddrParam])
      and not TIdSipParser.IsIPv6Reference(Self.Parameters.Values[MaddrParam]) then
      Self.FailParse;
  end;
end;

procedure TIdSipViaHeader.AssertReceivedWellFormed;
begin
  if (Self.IndexOfParam(ReceivedParam) > -1)
    and not TIdIPAddressParser.IsIPv4Address(Self.Params[ReceivedParam])
    and not TIdIPAddressParser.IsIPv6Address(Self.Params[ReceivedParam]) then
    Self.FailParse;
end;

procedure TIdSipViaHeader.AssertTTLWellFormed;
begin
  if (Self.Parameters.IndexOfName(TTLParam) > -1) then begin
    if not TIdSipParser.IsByte(Self.Parameters.Values[TTLParam]) then
      Self.FailParse;
  end;
end;

function TIdSipViaHeader.GetBranch: String;
begin
  if Self.HasParam(BranchParam) then
    Result := Self.Params[BranchParam]
  else
    Result := '';
end;

function TIdSipViaHeader.GetMaddr: String;
begin
  if Self.HasParam(MaddrParam) then
    Result := Self.Params[MaddrParam]
  else
    Result := '';
end;

function TIdSipViaHeader.GetReceived: String;
begin
  if Self.HasParam(ReceivedParam) then
    Result := Self.Params[ReceivedParam]
  else
    Result := '';
end;

function TIdSipViaHeader.GetRport: Cardinal;
begin
  if Self.HasParam(RportParam) then
    Result := StrToIntDef(Self.Params[RPortParam], 0)
  else
    Result := 0;
end;

function TIdSipViaHeader.GetTTL: Byte;
begin
  if Self.HasParam(TTLParam) then
    Result := StrToInt(Self.Params[TTLParam])
  else
    Result := 0;
end;

procedure TIdSipViaHeader.SetBranch(const Value: String);
begin
  Self.Params[BranchParam] := Value;

  Self.AssertBranchWellFormed;
end;

procedure TIdSipViaHeader.SetMaddr(const Value: String);
begin
  Self.Params[MaddrParam] := Value;

  Self.AssertMaddrWellFormed;
end;

procedure TIdSipViaHeader.SetReceived(const Value: String);
begin
  Self.Params[ReceivedParam] := Value;

  Self.AssertReceivedWellFormed;
end;

procedure TIdSipViaHeader.SetRport(Value: Cardinal);
begin
  Self.Params[RportParam] := IntToStr(Value);
end;

procedure TIdSipViaHeader.SetTTL(Value: Byte);
begin
  Self.Params[TTLParam] := IntToStr(Value);
end;

//******************************************************************************
//* TIdSipWarningHeader                                                        *
//******************************************************************************
//* TIdSipWarningHeader Protected methods **************************************

function TIdSipWarningHeader.GetName: String;
begin
  Result := WarningHeader;
end;

function TIdSipWarningHeader.GetValue: String;
begin
  Result := Format('%d %s "%s"', [Self.Code, Self.Agent, Self.EncodeQuotedStr(Self.Text)]);
end;

procedure TIdSipWarningHeader.SetValue(const Value: String);
var
  S: String;
  Token: String;
begin
  S := Value;

  Token := Fetch(S, ' ');
  if not TIdSipParser.IsNumber(Token) or (Length(Token) <> 3) then
    Self.FailParse;
  Self.Code := StrToInt(Token);

  Token := Fetch(S, ' ');
  if not TIdSipParser.IsToken(Token) then
    Self.FailParse;
  Self.Agent := Token;

  if not TIdSipParser.IsQuotedString(S) then
    Self.FailParse;

  DecodeQuotedStr(Copy(S, 2, Length(S) - 2), S);
  Self.Text := S;
end;

//******************************************************************************
//* TIdSipWWWAuthenticateHeader                                                *
//******************************************************************************

//* TIdSipWWWAuthenticateHeader Protected methods ******************************

function TIdSipWWWAuthenticateHeader.GetName: String;
begin
  Result := WWWAuthenticateHeader;
end;

//******************************************************************************
//* TIdSipHeaderMap                                                            *
//******************************************************************************
//* TIdSipHeaderMap Public methods *********************************************

constructor TIdSipHeaderMap.Create(HeaderName: String; HeaderClass: TIdSipHeaderClass);
begin
  inherited Create;

  fHeaderName := HeaderName;
  fHeaderClass  := HeaderClass;
end;

//******************************************************************************
//* TIdSipHeaderList                                                           *
//******************************************************************************
//* TIdSipHeaderList Public methods ********************************************

class function TIdSipHeaderList.CanonicaliseName(HeaderName: String): String;
begin
  Result := '';

  if not Assigned(GCanonicalHeaderNames) then begin
    GCanonicalHeaderNames := TStringList.Create;
    GCanonicalHeaderNames.Add(AcceptHeader               + '=' + AcceptHeader);
    GCanonicalHeaderNames.Add(AcceptEncodingHeader       + '=' + AcceptEncodingHeader);
    GCanonicalHeaderNames.Add(AcceptLanguageHeader       + '=' + AcceptLanguageHeader);
    GCanonicalHeaderNames.Add(AlertInfoHeader            + '=' + AlertInfoHeader);
    GCanonicalHeaderNames.Add(AllowHeader                + '=' + AllowHeader);
    GCanonicalHeaderNames.Add(AuthenticationInfoHeader   + '=' + AuthenticationInfoHeader);
    GCanonicalHeaderNames.Add(AuthorizationHeader        + '=' + AuthorizationHeader);
    GCanonicalHeaderNames.Add(CallIDHeaderFull           + '=' + CallIDHeaderFull);
    GCanonicalHeaderNames.Add(CallIDHeaderShort          + '=' + CallIDHeaderFull);
    GCanonicalHeaderNames.Add(CallInfoHeader             + '=' + CallInfoHeader);
    GCanonicalHeaderNames.Add(ContactHeaderFull          + '=' + ContactHeaderFull);
    GCanonicalHeaderNames.Add(ContactHeaderShort         + '=' + ContactHeaderFull);
    GCanonicalHeaderNames.Add(ContentDispositionHeader   + '=' + ContentDispositionHeader);
    GCanonicalHeaderNames.Add(ContentEncodingHeaderFull  + '=' + ContentEncodingHeaderFull);
    GCanonicalHeaderNames.Add(ContentEncodingHeaderShort + '=' + ContentEncodingHeaderFull);
    GCanonicalHeaderNames.Add(ContentLanguageHeader      + '=' + ContentLanguageHeader);
    GCanonicalHeaderNames.Add(ContentLengthHeaderFull    + '=' + ContentLengthHeaderFull);
    GCanonicalHeaderNames.Add(ContentLengthHeaderShort   + '=' + ContentLengthHeaderFull);
    GCanonicalHeaderNames.Add(ContentTypeHeaderFull      + '=' + ContentTypeHeaderFull);
    GCanonicalHeaderNames.Add(ContentTypeHeaderShort     + '=' + ContentTypeHeaderFull);
    GCanonicalHeaderNames.Add(CSeqHeader                 + '=' + CSeqHeader);
    GCanonicalHeaderNames.Add(DateHeader                 + '=' + DateHeader);
    GCanonicalHeaderNames.Add(ErrorInfoHeader            + '=' + ErrorInfoHeader);
    GCanonicalHeaderNames.Add(ExpiresHeader              + '=' + ExpiresHeader);
    GCanonicalHeaderNames.Add(FromHeaderFull             + '=' + FromHeaderFull);
    GCanonicalHeaderNames.Add(FromHeaderShort            + '=' + FromHeaderFull);
    GCanonicalHeaderNames.Add(InReplyToHeader            + '=' + InReplyToHeader);
    GCanonicalHeaderNames.Add(MaxForwardsHeader          + '=' + MaxForwardsHeader);
    GCanonicalHeaderNames.Add(MIMEVersionHeader          + '=' + MIMEVersionHeader);
    GCanonicalHeaderNames.Add(MinExpiresHeader           + '=' + MinExpiresHeader);
    GCanonicalHeaderNames.Add(OrganizationHeader         + '=' + OrganizationHeader);
    GCanonicalHeaderNames.Add(PriorityHeader             + '=' + PriorityHeader);
    GCanonicalHeaderNames.Add(ProxyAuthenticateHeader    + '=' + ProxyAuthenticateHeader);
    GCanonicalHeaderNames.Add(ProxyAuthorizationHeader   + '=' + ProxyAuthorizationHeader);
    GCanonicalHeaderNames.Add(ProxyRequireHeader         + '=' + ProxyRequireHeader);
    GCanonicalHeaderNames.Add(RecordRouteHeader          + '=' + RecordRouteHeader);
    GCanonicalHeaderNames.Add(ReplyToHeader              + '=' + ReplyToHeader);
    GCanonicalHeaderNames.Add(RequireHeader              + '=' + RequireHeader);
    GCanonicalHeaderNames.Add(RetryAfterHeader           + '=' + RetryAfterHeader);
    GCanonicalHeaderNames.Add(RouteHeader                + '=' + RouteHeader);
    GCanonicalHeaderNames.Add(ServerHeader               + '=' + ServerHeader);
    GCanonicalHeaderNames.Add(SubjectHeaderFull          + '=' + SubjectHeaderFull);
    GCanonicalHeaderNames.Add(SubjectHeaderShort         + '=' + SubjectHeaderFull);
    GCanonicalHeaderNames.Add(SupportedHeaderFull        + '=' + SupportedHeaderFull);
    GCanonicalHeaderNames.Add(SupportedHeaderShort       + '=' + SupportedHeaderFull);
    GCanonicalHeaderNames.Add(TimestampHeader            + '=' + TimestampHeader);
    GCanonicalHeaderNames.Add(ToHeaderFull               + '=' + ToHeaderFull);
    GCanonicalHeaderNames.Add(ToHeaderShort              + '=' + ToHeaderFull);
    GCanonicalHeaderNames.Add(UnsupportedHeader          + '=' + UnsupportedHeader);
    GCanonicalHeaderNames.Add(UserAgentHeader            + '=' + UserAgentHeader);
    GCanonicalHeaderNames.Add(ViaHeaderFull              + '=' + ViaHeaderFull);
    GCanonicalHeaderNames.Add(ViaHeaderShort             + '=' + ViaHeaderFull);
    GCanonicalHeaderNames.Add(WarningHeader              + '=' + WarningHeader);
    GCanonicalHeaderNames.Add(WWWAuthenticateHeader      + '=' + WWWAuthenticateHeader);
  end;

  if (GCanonicalHeaderNames.IndexOfName(HeaderName) > -1) then
    Result := GCanonicalHeaderNames.Values[HeaderName];

  if (Result = '') then begin
      Result := HeaderName;
  end;
end;

class function TIdSipHeaderList.GetHeaderName(Header: String): String;
begin
  Result := Trim(Fetch(Header, ':'));
end;

function TIdSipHeaderList.AsString: String;
begin
  Result := '';
  Self.First;

  while Self.HasNext do begin
    Result := Result + Self.CurrentHeader.AsString + EOL;
    Self.Next;
  end;
end;

function TIdSipHeaderList.HasEqualValues(const OtherHeaders: TIdSipHeaderList): Boolean;
begin
  Result := Self.Count = OtherHeaders.Count;

  Self.First;
  OtherHeaders.First;
  if Result then begin
    while Result and Self.HasNext do begin
      Result := Result
            and (Self.CurrentHeader.Value = OtherHeaders.CurrentHeader.Value)
            and (Self.CurrentHeader.ParamsAsString = OtherHeaders.CurrentHeader.ParamsAsString);
      Self.Next;
      OtherHeaders.Next;
    end;
  end;
end;

function TIdSipHeaderList.Equals(OtherHeaders: TIdSipHeaderList): Boolean;
  procedure DumpHeaders(Headers: TIdSipHeaderList; List: TStringList);
  begin
    Headers.First;
    while Headers.HasNext do begin
      List.Add(Headers.CurrentHeader.AsString);
      Headers.Next;
    end;

    List.Sort;
  end;
var
  I:            Integer;
  OurHeaders:   TStringList;
  TheirHeaders: TStringList;
begin
  // In brief: TStringLists allow handy sorting of strings. We dump our
  // headers in one TStringList and their headers in another, sort the
  // lists and compare them. First though we try short-circuit the
  // comparison.

  Result := Self.Count = OtherHeaders.Count;

  if Result then begin
    OurHeaders := TStringList.Create;
    try
      TheirHeaders := TStringList.Create;
      try
        DumpHeaders(Self, OurHeaders);
        DumpHeaders(OtherHeaders, TheirHeaders);

        for I := 0 to OurHeaders.Count - 1 do
          Result := (OurHeaders[I] = TheirHeaders[I]);
      finally
        TheirHeaders.Free;
      end;
    finally
      OurHeaders.Free;
    end;
  end;
end;

function TIdSipHeaderList.IsEmpty: Boolean;
begin
  Result := Self.Count = 0;
end;

//* TIdSipHeaderList Protected methods *****************************************

class function TIdSipHeaderList.HeaderTypes: TObjectList;
begin
  if not Assigned(GIdSipHeadersMap) then begin
    GIdSipHeadersMap := TObjectList.Create(true);

    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(AcceptHeader,               TIdSipWeightedCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(AcceptEncodingHeader,       TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(AlertInfoHeader,            TIdSipUriHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(AllowHeader,                TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(AuthenticationInfoHeader,   TIdSipAuthenticateInfoHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(AuthorizationHeader,        TIdSipAuthorizationHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(CallIDHeaderFull,           TIdSipCallIDHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(CallIDHeaderShort,          TIdSipCallIDHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ContactHeaderFull,          TIdSipContactHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ContactHeaderShort,         TIdSipContactHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ContentDispositionHeader,   TIdSipContentDispositionHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ContentEncodingHeaderFull,  TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ContentEncodingHeaderShort, TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ContentLanguageHeader,      TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ContentLengthHeaderFull,    TIdSipNumericHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(CSeqHeader,                 TIdSipCSeqHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(DateHeader,                 TIdSipDateHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ErrorInfoHeader,            TIdSipUriHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ExpiresHeader,              TIdSipNumericHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(FromHeaderFull,             TIdSipFromHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(FromHeaderShort,            TIdSipFromHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(InReplyToHeader,            TIdSipCallIdHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(MaxForwardsHeader,          TIdSipMaxForwardsHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(MinExpiresHeader,           TIdSipNumericHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ProxyAuthenticateHeader,    TIdSipProxyAuthenticateHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ProxyAuthorizationHeader,   TIdSipProxyAuthorizationHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ProxyRequireHeader,         TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(RecordRouteHeader,          TIdSipRecordRouteHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(RequireHeader,              TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(RouteHeader,                TIdSipRouteHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(SupportedHeaderFull,        TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(SupportedHeaderShort,       TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(TimestampHeader,            TIdSipTimestampHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ToHeaderFull,               TIdSipToHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ToHeaderShort,              TIdSipToHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(UnsupportedHeader,          TIdSipCommaSeparatedHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ViaHeaderFull,              TIdSipViaHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(ViaHeaderShort,             TIdSipViaHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(WarningHeader,              TIdSipWarningHeader));
    GIdSipHeadersMap.Add(TIdSipHeaderMap.Create(WWWAuthenticateHeader,      TIdSipWWWAuthenticateHeader));
  end;

  Result := GIdSipHeadersMap;
end;

class function TIdSipHeaderList.IsHeader(const Header,
                                         ExpectedHeaderName: String): Boolean;
var
  Name: String;
begin
  Name := Self.GetHeaderName(Header);
  Result := IsEqual(Self.CanonicaliseName(Name), ExpectedHeaderName);
end;

function TIdSipHeaderList.ConstructHeader(HeaderName: String): TIdSipHeader;
var
  I: Integer;
begin
  HeaderName := Self.CanonicaliseName(HeaderName);

  Result := nil;
  I := 0;
  while (I < Self.HeaderTypes.Count) and not Assigned(Result) do
    if Self.IsHeader(TIdSipHeaderMap(Self.HeaderTypes[I]).HeaderName, HeaderName) then
      Result := TIdSipHeaderMap(Self.HeaderTypes[I]).HeaderClass.Create
    else
      Inc(I);

  if not Assigned(Result) then
    Result := TIdSipHeader.Create;
end;

//******************************************************************************
//* TIdSipHeadersFilter                                                        *
//******************************************************************************
//* TIdSipHeadersFilter Public methods *****************************************

constructor TIdSipHeadersFilter.Create(Headers: TIdSipHeaders;
                                       const HeaderName: String);
begin
  Self.fHeaderName := HeaderName;
  Self.Headers     := Headers;
end;

function TIdSipHeadersFilter.Add(const HeaderName: String): TIdSipHeader;
begin
  Result := Self.Headers.Add(HeaderName);
end;

procedure TIdSipHeadersFilter.Add(Header: TIdSipHeader);
begin
  Self.Headers.Add(Header);
end;

procedure TIdSipHeadersFilter.Add(Headers: TIdSipHeaderList);
begin
  Self.Headers.Add(Headers);
end;

procedure TIdSipHeadersFilter.Clear;
begin
  Self.Headers.RemoveAll(Self.HeaderName);
end;

function TIdSipHeadersFilter.Count: Integer;
begin
  Result := 0;
  Self.Headers.First;
  while Self.Headers.HasNext do begin
    if (Self.Headers.CurrentHeader.Name = Self.HeaderName) then
      Inc(Result);

    Self.Headers.Next;
  end;
end;

function TIdSipHeadersFilter.CurrentHeader: TIdSipHeader;
begin
  if Self.IsEmpty or (Self.CurrentIndex >= Self.Count) then
    Result := nil
  else
    Result := Self.GetItems(Self.CurrentIndex);
end;

procedure TIdSipHeadersFilter.First;
begin
  Self.CurrentIndex := 0;
end;

function TIdSipHeadersFilter.HasNext: Boolean;
begin
  Result := Self.CurrentIndex < Self.Count;
end;

procedure TIdSipHeadersFilter.Next;
begin
  Inc(Self.CurrentIndex);
end;

procedure TIdSipHeadersFilter.Remove(Header: TIdSipHeader);
begin
  Self.Headers.Remove(Header);
end;

procedure TIdSipHeadersFilter.RemoveAll;
begin
  Self.Headers.RemoveAll(Self.HeaderName);
end;

//* TIdSipHeadersFilter Protected methods **************************************

function TIdSipHeadersFilter.GetItems(Index: Integer): TIdSipHeader;
var
  ItemCount: Integer;
begin
  Result    := nil;
  ItemCount := -1;

  Self.Headers.First;
  while Self.Headers.HasNext and not Assigned(Result) do begin
    if (Self.Headers.CurrentHeader.Name = Self.HeaderName) then
      Inc(ItemCount);

    if (ItemCount = Index) then
      Result := Self.Headers.CurrentHeader;

    Self.Headers.Next;
  end;
end;

//******************************************************************************
//* TIdSipHeaders                                                              *
//******************************************************************************
//* TIdSipHeaders Public methods ***********************************************

class function TIdSipHeaders.IsCallID(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, CallIDHeaderFull);
end;

class function TIdSipHeaders.IsCompoundHeader(const Header: String): Boolean;
begin
  Result := Self.IsContact(Header)
         or Self.IsErrorInfo(Header)
         or Self.IsRecordRoute(Header)
         or Self.IsRoute(Header)
         or Self.IsVia(Header)
         or Self.IsWarning(Header);
end;

class function TIdSipHeaders.IsContact(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, ContactHeaderFull);
end;

class function TIdSipHeaders.IsContentLength(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, ContentLengthHeaderFull);
end;

class function TIdSipHeaders.IsCSeq(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, CseqHeader);
end;

class function TIdSipHeaders.IsErrorInfo(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, ErrorInfoHeader);
end;

class function TIdSipHeaders.IsFrom(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, FromHeaderFull);
end;

class function TIdSipHeaders.IsMaxForwards(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, MaxForwardsHeader);
end;

class function TIdSipHeaders.IsRecordRoute(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, RecordRouteHeader);
end;

class function TIdSipHeaders.IsRoute(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, RouteHeader);
end;

class function TIdSipHeaders.IsTo(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, ToHeaderFull);
end;

class function TIdSipHeaders.IsVia(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, ViaHeaderFull);
end;

class function TIdSipHeaders.IsWarning(const Header: String): Boolean;
begin
  Result := Self.IsHeader(Header, WarningHeader);
end;

constructor TIdSipHeaders.Create;
begin
  inherited Create;

  Self.List := TObjectList.Create(true);
end;

destructor TIdSipHeaders.Destroy;
begin
  Self.List.Free;

  inherited Destroy;
end;

function TIdSipHeaders.Add(const HeaderName: String): TIdSipHeader;
begin
  Result := Self.ConstructHeader(HeaderName);
  try
    Self.List.Add(Result);
    Result.Name := HeaderName;
  except
    if (Self.List.IndexOf(Result) <> -1) then begin
      Self.List.Remove(Result);
      Result := nil;
    end
    else
      FreeAndNil(Result);

    raise;
  end;
end;

procedure TIdSipHeaders.Add(Header: TIdSipHeader);
var
  H: TIdSipHeader;
begin
  H := Self.Add(Header.Name);

  if Assigned(H) then
    H.Assign(Header);
end;

procedure TIdSipHeaders.Add(Headers: TIdSipHeaderList);
begin
  Headers.First;
  while Headers.HasNext do begin
    Self.Add(Headers.CurrentHeader);
    Headers.Next;
  end;
end;

procedure TIdSipHeaders.AddInReverseOrder(Headers: TIdSipHeadersFilter);
var
  I: Integer;
begin
  for I := Headers.Count - 1 downto 0 do
    Self.Add(Headers.Items[I]);
end;

procedure TIdSipHeaders.Clear;
begin
  Self.List.Clear;
end;

function TIdSipHeaders.CurrentHeader: TIdSipHeader;
begin
  if Self.IsEmpty or (Self.CurrentIndex >= Self.Count) then
    Result := nil
  else
    Result := Self.List[Self.CurrentIndex] as TIdSipHeader;
end;

procedure TIdSipHeaders.Delete(I: Integer);
begin
  Self.List.Delete(I);
end;

function TIdSipHeaders.Count: Integer;
begin
  Result := Self.List.Count;
end;

procedure TIdSipHeaders.First;
begin
  Self.CurrentIndex := 0;
end;

function TIdSipHeaders.GetAllButFirst: TIdSipHeaderList;
begin
  Result := TIdSipHeaders.Create;
  try
    Self.First;

    if Self.HasNext then
      Self.Next;

    while Self.HasNext do begin
      (Result as TIdSipHeaders).Add(Self.CurrentHeader);
      Self.Next;
    end;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipHeaders.HasHeader(const HeaderName: String): Boolean;
begin
  Result := Assigned(Self.FindFirst(HeaderName));
end;

function TIdSipHeaders.HasNext: Boolean;
begin
  Result := Self.CurrentIndex < Self.Count;
end;

procedure TIdSipHeaders.Next;
begin
  Inc(Self.CurrentIndex);
end;

procedure TIdSipHeaders.Remove(Header: TIdSipHeader);
begin
  Self.List.Remove(Header);
end;

procedure TIdSipHeaders.RemoveAll(const HeaderName: String);
var
  I: Integer;
  H: TIdSipHeader;
begin
  I := 0;
  while (I < Self.List.Count) do begin
    H := Self.GetItems(I);
    if (IsEqual(H.Name, HeaderName)) then
      Self.Remove(H)
    else
      Inc(I);
  end;
end;

//* TIdSipHeaders Protected methods ********************************************

function TIdSipHeaders.GetItems(I: Integer): TIdSipHeader;
begin
  Result := Self.List[I] as TIdSipHeader;
end;

//* TIdSipHeaders Private methods **********************************************

function TIdSipHeaders.FindFirst(const HeaderName: String): TIdSipHeader;
var
  I: Integer;
begin
  Result := nil;

  I := 0;
  while (I < Self.List.Count) and not Assigned(Result) do
    if IsEqual((Self.List[I] as TIdSipHeader).Name, HeaderName) then
      Result := Self.List[I] as TIdSipHeader
    else
      Inc(I);
end;

function TIdSipHeaders.GetHeaders(const Name: String): TIdSipHeader;
begin
  Result := Self.FindFirst(Name);

  if not Assigned(Result) then
    Result := Self.Add(Name);
end;

//******************************************************************************
//* TIdSipContacts                                                             *
//******************************************************************************
//* TIdSipContacts Public methods **********************************************

constructor TIdSipContacts.Create(Headers: TIdSipHeaders);
begin
  inherited Create(Headers, ContactHeaderFull);
end;

constructor TIdSipContacts.Create;
begin
  Self.BlankHeaders := TIdSipHeaders.Create;
  inherited Create(Self.BlankHeaders, ContactHeaderFull);
end;

destructor TIdSipContacts.Destroy;
begin
  Self.BlankHeaders.Free;

  inherited Destroy;
end;

function TIdSipContacts.CurrentContact: TIdSipContactHeader;
begin
  Result := Self.CurrentHeader as TIdSipContactHeader;
end;


//******************************************************************************
//* TIdSipExpiresHeaders
//******************************************************************************
//* TIdSipExpiresHeaders Public methods ****************************************

constructor TIdSipExpiresHeaders.Create(Headers: TIdSipHeaders);
begin
  inherited Create(Headers, ExpiresHeader);
end;

function TIdSipExpiresHeaders.CurrentExpires: Cardinal;
var
  Header: TIdSipHeader;
begin
  Header := Self.CurrentHeader;


  if not Assigned(Header) then
    Result := 0
  else
    Result := (Header as TIdSipNumericHeader).NumericValue;
end;

//******************************************************************************
//* TIdSipRecordRoutePath                                                      *
//******************************************************************************
//* TIdSipRecordRoutePath Public methods ***************************************

constructor TIdSipRecordRoutePath.Create(Headers: TIdSipHeaders);
begin
  inherited Create(Headers, RecordRouteHeader);
end;

constructor TIdSipRecordRoutePath.Create;
begin
  Self.BlankHeaders := TIdSipHeaders.Create;
  inherited Create(Self.BlankHeaders, RecordRouteHeader);
end;

destructor TIdSipRecordRoutePath.Destroy;
begin
  Self.BlankHeaders.Free;

  inherited Destroy;
end;

function TIdSipRecordRoutePath.CurrentRecordRoute: TIdSipRecordRouteHeader;
begin
  Result := Self.CurrentHeader as TIdSipRecordRouteHeader;
end;

//******************************************************************************
//* TIdSipRoutePath                                                            *
//******************************************************************************
//* TIdSipRoutePath Public methods *********************************************

constructor TIdSipRoutePath.Create(Headers: TIdSipHeaders);
begin
  inherited Create(Headers, RouteHeader);
end;

constructor TIdSipRoutePath.Create;
begin
  Self.BlankHeaders := TIdSipHeaders.Create;
  inherited Create(Self.BlankHeaders, RouteHeader);
end;

destructor TIdSipRoutePath.Destroy;
begin
  Self.BlankHeaders.Free;

  inherited Destroy;
end;

procedure TIdSipRoutePath.AddRoute(RouteUri: TIdSipUri);
var
  NewRoute: TIdSipRouteHeader;
begin
  NewRoute := RouteUri.AsRouteHeader;
  try
    Self.Add(NewRoute);
  finally
    NewRoute.Free;
  end;
end;

function TIdSipRoutePath.CurrentRoute: TIdSipRouteHeader;
begin
  Result := Self.CurrentHeader as TIdSipRouteHeader;
end;

function TIdSipRoutePath.GetAllButFirst: TIdSipRoutePath;
begin
  Result := TIdSipRoutePath.Create;
  try
    Self.First;

    if Self.HasNext then
      Self.Next;

    while Self.HasNext do begin
      Result.Add(Self.CurrentHeader);
      Self.Next;
    end;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

//******************************************************************************
//* TIdSipViaPath                                                              *
//******************************************************************************
//* TIdSipViaPath Public methods ***********************************************

constructor TIdSipViaPath.Create(Headers: TIdSipHeaders);
begin
  inherited Create(Headers, ViaHeaderFull);
end;

function TIdSipViaPath.LastHop: TIdSipViaHeader;
begin
  Self.First;
  Result := Self.CurrentHeader as TIdSipViaHeader;
end;

function TIdSipViaPath.Length: Integer;
begin
  Result := Self.Count;
end;

procedure TIdSipViaPath.RemoveLastHop;
begin
  Self.Remove(Self.LastHop);
end;

//******************************************************************************
//* TIdSipMessage                                                              *
//******************************************************************************
//* TIdSipMessage Public methods ***********************************************

class function TIdSipMessage.WillEstablishDialog(Request: TIdSipRequest;
                                                 Response: TIdSipResponse): Boolean;
begin
  Result := Request.IsInvite and Response.IsOK;
end;

constructor TIdSipMessage.Create;
begin
  inherited Create;

  fHeaders := TIdSipHeaders.Create;
  fPath := TIdSipViaPath.Create(Self.Headers);
  fContacts := TIdSipContacts.Create(Self.Headers);

  Self.SIPVersion  := IdSipConsts.SIPVersion;
end;

destructor TIdSipMessage.Destroy;
begin
  Self.Contacts.Free;
  Self.Path.Free;
  Self.Headers.Free;

  inherited Destroy;
end;

procedure TIdSipMessage.Accept(Visitor: IIdSipMessageVisitor);
begin
end;

function TIdSipMessage.AddHeader(const HeaderName: String): TIdSipHeader;
begin
  Result := Self.Headers.Add(HeaderName)
end;

procedure TIdSipMessage.AddHeader(Header: TIdSipHeader);
begin
  Self.Headers.Add(Header);
end;

procedure TIdSipMessage.AddHeaders(Headers: TIdSipHeaderList);
begin
  Self.Headers.Add(Headers);
end;

procedure TIdSipMessage.Assign(Src: TPersistent);
var
  S: TIdSipMessage;
begin
  if (Src is TIdSipMessage) then begin
    S := Src as TIdSipMessage;

    Self.SIPVersion := S.SIPVersion;

    Self.ClearHeaders;
    Self.AddHeaders(S.Headers);
    
    Self.Body := S.Body;
  end
  else
    inherited Assign(Src);
end;

function TIdSipMessage.AsString: String;
begin
  Result := Self.FirstLine;

  Result := Result + Self.Headers.AsString;

  Result := Result + EOL;
  Result := Result + Self.Body;
end;

procedure TIdSipMessage.ClearHeaders;
begin
  Self.Headers.Clear;
end;

function TIdSipMessage.ContactCount: Cardinal;
var
  Contacts: TIdSipContacts;
begin
  Contacts := TIdSipContacts.Create(Self.Headers);
  try
    Result := Contacts.Count;
  finally
    Contacts.Free;
  end;
end;

function TIdSipMessage.Copy: TIdSipMessage;
begin
  Result := TIdSipMessageClass(Self.ClassType).Create;
  Result.Assign(Self);
end;

function TIdSipMessage.FirstContact: TIdSipContactHeader;
begin
  Result := Self.FirstHeader(ContactHeaderFull) as TIdSipContactHeader;
end;

function TIdSipMessage.FirstExpires: TIdSipNumericHeader;
begin
  Result := Self.FirstHeader(ExpiresHeader) as TIdSipNumericHeader;
end;

function TIdSipMessage.FirstHeader(const HeaderName: String): TIdSipHeader;
begin
  Result := Self.Headers[HeaderName];
end;

function TIdSipMessage.FirstMinExpires: TIdSipNumericHeader;
begin
  Result := Self.FirstHeader(MinExpiresHeader) as TIdSipNumericHeader;
end;

function TIdSipMessage.FirstRequire: TIdSipCommaSeparatedHeader;
begin
  Result := Self.FirstHeader(RequireHeader) as TIdSipCommaSeparatedHeader;
end;

function TIdSipMessage.HasExpiry: Boolean;
var
  Contacts: TIdSipContacts;
begin
  Result := Self.HasHeader(ExpiresHeader);

  if not Result then begin
    Contacts := TIdSipContacts.Create(Self.Headers);
    try
      Contacts.First;
      while Contacts.HasNext and not Result do begin
        Result := Result or Contacts.CurrentHeader.HasParam(ExpiresParam);
        Contacts.Next;
      end;
    finally
      Contacts.Free;
    end;
  end;
end;

function TIdSipMessage.HasHeader(const HeaderName: String): Boolean;
begin
  Result := Self.Headers.HasHeader(HeaderName);
end;

function TIdSipMessage.HeaderCount: Integer;
begin
  Result := Self.Headers.Count;
end;

function TIdSipMessage.QuickestExpiry: Cardinal;
begin
  if not Self.HasExpiry then
    Result := 0
  else begin
    Result := Self.Minimum(Self.QuickestContactExpiry,
                           Self.QuickestExpiresHeader)
  end;
end;

function TIdSipMessage.LastHop: TIdSipViaHeader;
begin
  Result := Self.Path.LastHop;
end;

procedure TIdSipMessage.ReadBody(Src: TStream);
const
  BufLen = 100;
var
  Buf:         array[1..BufLen] of Char;
  BytesToRead: Integer;
  Read:        Integer;
begin
  // The transport must set Content-Length before this method gets called!

  if (Self.ContentLength > 0) then begin
    BytesToRead := Self.ContentLength;

    repeat
      Read := Src.Read(Buf, Min(BufLen, BytesToRead));
      Dec(BytesToRead, Read);

      Self.Body := Self.Body + System.Copy(Buf, 1, Read);
    until (Read < BufLen) or (BytesToRead <= 0);
  end;
end;

procedure TIdSipMessage.RemoveHeader(Header: TIdSipHeader);
begin
  Self.Headers.Remove(Header);
end;

procedure TIdSipMessage.RemoveAllHeadersNamed(const Name: String);
begin
  Self.Headers.RemoveAll(Name);
end;

//* TIdSipMessage Private methods **********************************************

function TIdSipMessage.GetCallID: String;
begin
  Result := Self.FirstHeader(CallIDHeaderFull).Value;
end;

function TIdSipMessage.GetContentDisposition: TIdSipContentDispositionHeader;
begin
  Result := Self.FirstHeader(ContentDispositionHeader) as TIdSipContentDispositionHeader;
end;

function TIdSipMessage.GetContentLanguage: String;
begin
  Result := Self.FirstHeader(ContentLanguageHeader).Value;
end;

function TIdSipMessage.GetContentLength: Cardinal;
begin
  Result := StrToInt(Self.FirstHeader(ContentLengthHeaderFull).Value);
end;

function TIdSipMessage.GetContentType: String;
begin
  Result := Self.FirstHeader(ContentTypeHeaderFull).Value;
end;

function TIdSipMessage.GetCSeq: TIdSipCSeqHeader;
begin
  Result := Self.FirstHeader(CSeqHeader) as TIdSipCSeqHeader;
end;

function TIdSipMessage.GetFrom: TIdSipFromHeader;
begin
  Result := Self.FirstHeader(FromHeaderFull) as TIdSipFromHeader;
end;

function TIdSipMessage.GetTo: TIdSipToHeader;
begin
  Result := Self.FirstHeader(ToHeaderFull) as TIdSipToHeader;
end;

function TIdSipMessage.Minimum(A, B: Cardinal): Cardinal;
begin
  // We can't use Min() because that takes two Integers.
  if (A < B) then
    Result := A
  else
    Result := B;
end;

function TIdSipMessage.QuickestContactExpiry: Cardinal;
var
  Contacts: TIdSipContacts;
begin
  Result := High(Result);
  Contacts := TIdSipContacts.Create(Self.Headers);
  try
    if not Contacts.IsEmpty then begin
      Contacts.First;

      while Contacts.HasNext do begin
        if Contacts.CurrentContact.WillExpire then
          Result := Self.Minimum(Result, Contacts.CurrentContact.Expires);
        Contacts.Next;
      end;
    end;
  finally
    Contacts.Free;
  end;
end;

function TIdSipMessage.QuickestExpiresHeader: Cardinal;
var
  Expires: TIdSipExpiresHeaders;
begin
  Result := High(Result);
  Expires := TIdSipExpiresHeaders.Create(Self.Headers);
  try
    if not Expires.IsEmpty then begin
      Expires.First;

      while Expires.HasNext do begin
        Result := Self.Minimum(Result, Expires.CurrentExpires);
        Expires.Next;
      end;
    end;
  finally
    Expires.Free;
  end;
end;

procedure TIdSipMessage.SetCallID(const Value: String);
begin
  Self.FirstHeader(CallIDHeaderFull).Value := Value;
end;

procedure TIdSipMessage.SetContacts(Value: TIdSipContacts);
begin
  Self.Contacts.Clear;
  Self.Contacts.Add(Value);
end;

procedure TIdSipMessage.SetContentDisposition(Value: TIdSipContentDispositionHeader);
begin
  Self.ContentDisposition.Assign(Value);
end;

procedure TIdSipMessage.SetContentLanguage(const Value: String);
begin
  Self.FirstHeader(ContentLanguageHeader).Value := Value;
end;

procedure TIdSipMessage.SetContentLength(Value: Cardinal);
begin
  Self.FirstHeader(ContentLengthHeaderFull).Value := IntToStr(Value);
end;

procedure TIdSipMessage.SetContentType(const Value: String);
begin
  Self.FirstHeader(ContentTypeHeaderFull).Value := Value;
end;

procedure TIdSipMessage.SetCSeq(Value: TIdSipCSeqHeader);
begin
  Self.CSeq.Assign(Value);
end;

procedure TIdSipMessage.SetFrom(Value: TIdSipFromHeader);
begin
  Self.FirstHeader(FromHeaderFull).Assign(Value);
end;

procedure TIdSipMessage.SetPath(Value: TIdSipViaPath);
begin
  Self.Path.Clear;
  Self.Path.Add(Value);
end;

procedure TIdSipMessage.SetTo(Value: TIdSipToHeader);
begin
  Self.FirstHeader(ToHeaderFull).Assign(Value);
end;

//*******************************************************************************
//* TIdSipRequest                                                               *
//*******************************************************************************
//* TIdSipRequest Public methods ************************************************

constructor TIdSipRequest.Create;
begin
  inherited Create;

  fRecordRoute := TIdSipRecordRoutePath.Create(Self.Headers);
  fRequestUri  := TIdSipURI.Create('');
  fRoute       := TIdSipRoutePath.Create(Self.Headers);

  Self.ContentLength := 0;
  Self.MaxForwards   := Self.DefaultMaxForwards;
end;

destructor TIdSipRequest.Destroy;
begin
  Self.Route.Free;
  Self.RequestUri.Free;
  Self.RecordRoute.Free;

  inherited Destroy;
end;

procedure TIdSipRequest.Accept(Visitor: IIdSipMessageVisitor);
begin
  Visitor.VisitRequest(Self);
end;

function TIdSipRequest.AckFor(Response: TIdSipResponse): TIdSipRequest;
var
  Routes: TIdSipRoutePath;
begin
  Result := TIdSipRequest.Create;
  try
    if Response.WillEstablishDialog(Self) then begin
      Result.RequestUri := Self.RequestUri;
      Result.CallID   := Response.CallID;
      Result.CSeq     := Response.CSeq;
      Result.From     := Self.From;
      Result.Method   := MethodAck;
      Result.ToHeader := Response.ToHeader;

      Result.CSeq.Method := Result.Method;
      Result.AddHeader(Response.LastHop);
      Result.LastHop.Branch := GRandomNumber.NextSipUserAgentTag;

      Result.AddHeaders(Self.Route);
    end
    else begin
      Result.Method          := MethodAck;
      Result.RequestUri      := Self.RequestUri;
      Result.SIPVersion      := Self.SIPVersion;
      Result.CallID          := Self.CallID;
      Result.From            := Self.From;
      Result.MaxForwards     := Result.DefaultMaxForwards;
      Result.ToHeader        := Response.ToHeader;
      Result.Path.Add(Self.LastHop);
      Result.CSeq.SequenceNo := Self.CSeq.SequenceNo;
      Result.CSeq.Method     := MethodAck;
      Result.ContentLength   := 0;
      Result.Body            := '';

      Routes := TIdSipRoutePath.Create(Response.Headers);
      try
        Result.AddHeaders(Routes);
      finally
        Routes.Free;
      end;
    end;

    if Self.HasHeader(AuthorizationHeader) then
      Result.AddHeader(AuthorizationHeader).Value := Self.FirstHeader(AuthorizationHeader).FullValue;
    if Self.HasHeader(ProxyAuthorizationHeader) then
      Result.AddHeader(ProxyAuthorizationHeader).Value := Self.FirstHeader(ProxyAuthorizationHeader).FullValue;
  except
    Result.Free;

    raise;
  end;
end;

function TIdSipRequest.AddressOfRecord: String;
begin
  Result := Self.ToHeader.AsAddressOfRecord;
end;

procedure TIdSipRequest.Assign(Src: TPersistent);
var
  R: TIdSipRequest;
begin
  inherited Assign(Src);

  R := Src as TIdSipRequest;

  Self.Method     := R.Method;
  Self.RequestUri := R.RequestUri;
end;

function TIdSipRequest.CreateCancel: TIdSipRequest;
begin
  Assert(Self.IsInvite, 'Only INVITE requests may be CANCELled');
  Result := TIdSipRequest.Create;
  try
    Result.Method      := MethodCancel;
    Result.CSeq.Method := Result.Method;

    Result.RequestUri.Uri  := Self.RequestUri.Uri;
    Result.CallID          := Self.CallID;
    Result.ToHeader        := Self.ToHeader;
    Result.CSeq.SequenceNo := Self.CSeq.SequenceNo;
    Result.From            := Self.From;

    Result.Path.Add(Self.LastHop);

    Result.Route := Self.Route;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipRequest.DefaultMaxForwards: Cardinal;
begin
  Result := 70;
end;

function TIdSipRequest.FirstAuthorization: TIdSipAuthorizationHeader;
begin
  Result := Self.FirstHeader(AuthorizationHeader) as TIdSipAuthorizationHeader
end;

function TIdSipRequest.FirstProxyAuthorization: TIdSipProxyAuthorizationHeader;
begin
  Result := Self.FirstHeader(ProxyAuthorizationHeader) as TIdSipProxyAuthorizationHeader
end;

function TIdSipRequest.FirstProxyRequire: TIdSipCommaSeparatedHeader;
begin
  Result := Self.FirstHeader(ProxyRequireHeader) as TIdSipCommaSeparatedHeader;
end;

function TIdSipRequest.HasAuthorization: Boolean;
begin
  Result := Self.HasHeader(AuthorizationHeader);
end;

function TIdSipRequest.HasProxyAuthorization: Boolean;
begin
  Result := Self.HasHeader(ProxyAuthorizationHeader);
end;

function TIdSipRequest.HasSipsUri: Boolean;
var
  S: String;
begin
  S := Self.RequestUri.URI;
  Result := Lowercase(Fetch(S, ':')) = SipsScheme;
end;

function TIdSipRequest.IsAck: Boolean;
begin
  Result := Self.Method = MethodAck;
end;

function TIdSipRequest.IsBye: Boolean;
begin
  Result := Self.Method = MethodBye;
end;

function TIdSipRequest.IsCancel: Boolean;
begin
  Result := Self.Method = MethodCancel;
end;

function TIdSipRequest.Equals(Msg: TIdSipMessage): Boolean;
var
  Request: TIdSipRequest;
begin
  if (Msg is Self.ClassType) then begin
    Request := Msg as TIdSipRequest;

    Result := (Self.SIPVersion     = Request.SIPVersion)
          and (Self.Method         = Request.Method)
          and (Self.RequestUri.URI = Request.RequestUri.URI)
          and (Self.Headers.Equals(Request.Headers));
  end
  else
    Result := false;
end;

function TIdSipRequest.IsInvite: Boolean;
begin
  Result := Self.Method = MethodInvite;
end;

function TIdSipRequest.IsRegister: Boolean;
begin
  Result := Self.Method = MethodRegister;
end;

function TIdSipRequest.IsRequest: Boolean;
begin
  Result := true;
end;

function TIdSipRequest.MalformedException: EBadMessageClass;
begin
  Result := EBadRequest;
end;

function TIdSipRequest.Match(Msg: TIdSipMessage): Boolean;
begin
  // If Self represents an initial request for a transaction, does Msg belong
  // to the same transaction?

  Result := Msg.MatchRequest(Self);
end;

function TIdSipRequest.RequiresResponse: Boolean;
begin
  Result := not Self.IsAck;
end;

//* TIdSipRequest Protected methods ********************************************

function TIdSipRequest.FirstLine: String;
begin
  Result := Format(RequestLine,
                   [Self.Method, Self.RequestUri.URI, Self.SIPVersion]);
end;

function TIdSipRequest.MatchRequest(InitialRequest: TIdSipRequest): Boolean;
begin
  // cf. RFC 3261 section 17.2.3
  if Self.LastHop.IsRFC3261Branch then
    Result := Self.MatchSip2Request(InitialRequest)
  else
    Result := Self.MatchSip1Request(InitialRequest)
end;

//* TIdSipRequest Private methods **********************************************

function TIdSipRequest.GetMaxForwards: Byte;
begin
  if (Self.FirstHeader(MaxForwardsHeader).Value = '') then
    Self.MaxForwards := Self.DefaultMaxForwards;

  Result := StrToInt(Self.FirstHeader(MaxForwardsHeader).Value);
end;

function TIdSipRequest.MatchSip1Request(InitialRequest: TIdSipRequest): Boolean;
begin
  // NOTE BENE:
  // This DOES NOT consistitute a full match! If Self.IsAck then we also
  // need to check the To tag against the response the server sent. We
  // cannot do that here, which means that only a(n INVITE) transaction can
  // do the full match.                                                                   
  if Self.IsInvite then
    Result := Self.RequestUri.Equals(InitialRequest.RequestUri)
         and (Self.ToHeader.Tag = InitialRequest.ToHeader.Tag)
         and (Self.From.Tag = InitialRequest.From.Tag)
         and (Self.CallID = InitialRequest.CallID)
         and  Self.CSeq.Equals(InitialRequest.CSeq)
         and  Self.LastHop.Equals(InitialRequest.LastHop)
  else if Self.IsAck then
    Result := RequestUri.Equals(InitialRequest.RequestUri)
         and (Self.From.Tag = InitialRequest.From.Tag)
         and (Self.CallID = InitialRequest.CallID)
         and (Self.CSeq.SequenceNo = InitialRequest.CSeq.SequenceNo)
         and  Self.LastHop.Equals(InitialRequest.LastHop)
  else
    Result := false;
end;

function TIdSipRequest.MatchSip2Request(InitialRequest: TIdSipRequest): Boolean;
begin
  Result := (Self.LastHop.Branch = InitialRequest.LastHop.Branch)
             and (Self.LastHop.SentBy = InitialRequest.LastHop.SentBy);

  if not Self.IsCancel then begin
    if Self.IsACK then
      Result := Result and InitialRequest.IsInvite
    else
      Result := Result and (Self.Method = InitialRequest.Method);
  end;
end;

procedure TIdSipRequest.SetMaxForwards(Value: Byte);
begin
  Self.FirstHeader(MaxForwardsHeader).Value := IntToStr(Value);
end;

procedure TIdSipRequest.SetRecordRoute(Value: TIdSipRecordRoutePath);
begin
  Self.RecordRoute.Clear;
  Self.RecordRoute.Add(Value);
end;

procedure TIdSipRequest.SetRequestUri(Value: TIdSipURI);
begin
  Self.fRequestUri.URI := Value.URI
end;

procedure TIdSipRequest.SetRoute(Value: TIdSipRoutePath);
begin
  Self.Route.Clear;
  Self.Route.Add(Value);
end;

//*******************************************************************************
//* TIdSipResponse                                                              *
//*******************************************************************************
//* TIdSipResponse Public methods ***********************************************

class function TIdSipResponse.InResponseTo(Request: TIdSipRequest;
                                           StatusCode: Cardinal): TIdSipResponse;
var
  TimestampHeaders: TIdSipHeadersFilter;
begin
  Result := TIdSipResponse.Create;
  try
    Result.StatusCode := StatusCode;

    // cf RFC 3261 section 8.2.6.1
    if Result.IsTrying then begin
      TimestampHeaders := TIdSipHeadersFilter.Create(Request.Headers,
                                                     TimestampHeader);
      try
        Result.AddHeaders(TimestampHeaders);
      finally
        TimestampHeaders.Free;
      end;
    end;

    // cf RFC 3261 section 8.2.6.2
    Result.Path         := Request.Path;
    Result.CallID       := Request.CallID;
    Result.CSeq         := Request.CSeq;
    Result.From         := Request.From;
    Result.ToHeader     := Request.ToHeader;
  except
    Result.Free;

    raise;
  end;
end;

class function TIdSipResponse.InResponseTo(Request: TIdSipRequest;
                                           StatusCode: Cardinal;
                                           Contact: TIdSipContactHeader): TIdSipResponse;
var
  NewContact:       TIdSipContactHeader;
  FirstRR:          TIdSipRecordRouteHeader;
  ReqRecordRoutes:  TIdSipHeadersFilter;
begin
  Result := Self.InResponseTo(Request, StatusCode);

  if Result.WillEstablishDialog(Request) then begin
    // cf RFC 3261 section 12.1.1
    ReqRecordRoutes := TIdSipHeadersFilter.Create(Request.Headers,
                                                  RecordRouteHeader);
    try
      Result.AddHeaders(ReqRecordRoutes);

      NewContact := TIdSipContactHeader.Create;
      try
        NewContact.Assign(Contact);

        if not ReqRecordRoutes.IsEmpty then begin
          ReqRecordRoutes.First;

          FirstRR := ReqRecordRoutes.CurrentHeader as TIdSipRecordRouteHeader;
          if (FirstRR.Address.IsSecure) then
            NewContact.Address.Scheme := SipsScheme;
        end;

        if Request.HasSipsUri then
          NewContact.Address.Scheme := SipsScheme;

        Result.AddHeader(NewContact);
      finally
        NewContact.Free;
      end;
    finally
      ReqRecordRoutes.Free;
    end;
  end;
end;

procedure TIdSipResponse.Accept(Visitor: IIdSipMessageVisitor);
begin
  Visitor.VisitResponse(Self);
end;

procedure TIdSipResponse.Assign(Src: TPersistent);
var
  R: TIdSipResponse;
begin
  inherited Assign(Src);

  R := Src as TIdSipResponse;

  Self.StatusCode := R.StatusCode;
  Self.StatusText := R.StatusText;
end;

function TIdSipResponse.Description: String;
begin
  Result := IntToStr(Self.StatusCode) + ' ' + Self.StatusText;
end;

function TIdSipResponse.FirstProxyAuthenticate: TIdSipProxyAuthenticateHeader;
begin
  Result := Self.FirstHeader(ProxyAuthenticateHeader) as TIdSipProxyAuthenticateHeader;
end;

function TIdSipResponse.FirstUnsupported: TIdSipCommaSeparatedHeader;
begin
  Result := Self.FirstHeader(UnsupportedHeader) as TIdSipCommaSeparatedHeader;
end;

function TIdSipResponse.FirstWWWAuthenticate: TIdSipWWWAuthenticateHeader;
begin
  Result := Self.FirstHeader(WWWAuthenticateHeader) as TIdSipWWWAuthenticateHeader;
end;

function TIdSipResponse.Equals(Msg: TIdSipMessage): Boolean;
var
  Response: TIdSipResponse;
begin
  if (Msg is Self.ClassType) then begin
    Response := Msg as TIdSipResponse;

    Result := (Self.SIPVersion = Response.SipVersion)
          and (Self.StatusCode = Response.StatusCode)
          and (Self.StatusText = Response.StatusText)
          and (Self.Headers.Equals(Response.Headers));
  end
  else
    Result := false;
end;

function TIdSipResponse.HasAuthenticationInfo: Boolean;
begin
  Result := Self.HasHeader(AuthenticationInfoHeader);
end;

function TIdSipResponse.HasProxyAuthenticate: Boolean;
begin
  Result := Self.HasHeader(ProxyAuthenticateHeader);
end;

function TIdSipResponse.HasWWWAuthenticate: Boolean;
begin
  Result := Self.HasHeader(WWWAuthenticateHeader);
end;

function TIdSipResponse.IsFinal: Boolean;
begin
  Result := Self.StatusCode div 100 > 1;
end;

function TIdSipResponse.IsOK: Boolean;
begin
  Result := Self.StatusCode div 100 = 2;
end;

function TIdSipResponse.IsProvisional: Boolean;
begin
  Result := Self.StatusCode div 100 = 1;
end;

function TIdSipResponse.IsRequest: Boolean;
begin
  Result := false;
end;

function TIdSipResponse.IsTrying: Boolean;
begin
  Result := Self.StatusCode = SIPTrying;
end;

function TIdSipResponse.MalformedException: EBadMessageClass;
begin
  Result := EBadResponse;
end;

function TIdSipResponse.WillEstablishDialog(Request: TIdSipRequest): Boolean;
begin
  Result := TIdSipResponse.WillEstablishDialog(Request, Self);
end;

//* TIdSipResponse Protected methods *******************************************

function TIdSipResponse.FirstLine: String;
begin
  Result := Format(StatusLine,
                   [Self.SIPVersion, Self.StatusCode, Self.StatusText]);
end;

function TIdSipResponse.MatchRequest(InitialRequest: TIdSipRequest): Boolean;
begin
  // cf. RFC 3261 section 17.1.3
  Result := not Self.Path.IsEmpty
        and not InitialRequest.Path.IsEmpty;

  Result := Result
        and (Self.LastHop.Branch = InitialRequest.LastHop.Branch);

  if (Self.CSeq.Method = MethodAck) then
    Result := Result
          and (InitialRequest.IsInvite)
  else
    Result := Result
          and (Self.CSeq.Method = InitialRequest.Method);
end;

//* TIdSipResponse Private methods **********************************************

procedure TIdSipResponse.SetStatusCode(Value: Integer);
begin
  Self.fStatusCode := Value;

  case Self.StatusCode of
    SIPTrying:                           Self.StatusText := RSSIPTrying;
    SIPRinging:                          Self.StatusText := RSSIPRinging;
    SIPCallIsBeingForwarded:             Self.StatusText := RSSIPCallIsBeingForwarded;
    SIPQueued:                           Self.StatusText := RSSIPQueued;
    SIPSessionProgess:                   Self.StatusText := RSSIPSessionProgess;
    SIPOK:                               Self.StatusText := RSSIPOK;
    SIPMultipleChoices:                  Self.StatusText := RSSIPMultipleChoices;
    SIPMovedPermanently:                 Self.StatusText := RSSIPMovedPermanently;
    SIPMovedTemporarily:                 Self.StatusText := RSSIPMovedTemporarily;
    SIPUseProxy:                         Self.StatusText := RSSIPUseProxy;
    SIPAlternativeService:               Self.StatusText := RSSIPAlternativeService;
    SIPBadRequest:                       Self.StatusText := RSSIPBadRequest;
    SIPUnauthorized:                     Self.StatusText := RSSIPUnauthorized;
    SIPPaymentRequired:                  Self.StatusText := RSSIPPaymentRequired;
    SIPForbidden:                        Self.StatusText := RSSIPForbidden;
    SIPNotFound:                         Self.StatusText := RSSIPNotFound;
    SIPMethodNotAllowed:                 Self.StatusText := RSSIPMethodNotAllowed;
    SIPNotAcceptableClient:              Self.StatusText := RSSIPNotAcceptableClient;
    SIPProxyAuthenticationRequired:      Self.StatusText := RSSIPProxyAuthenticationRequired;
    SIPRequestTimeout:                   Self.StatusText := RSSIPRequestTimeout;
    SIPGone:                             Self.StatusText := RSSIPGone;
    SIPRequestEntityTooLarge:            Self.StatusText := RSSIPRequestEntityTooLarge;
    SIPRequestURITooLarge:               Self.StatusText := RSSIPRequestURITooLarge;
    SIPUnsupportedMediaType:             Self.StatusText := RSSIPUnsupportedMediaType;
    SIPUnsupportedURIScheme:             Self.StatusText := RSSIPUnsupportedURIScheme;
    SIPBadExtension:                     Self.StatusText := RSSIPBadExtension;
    SIPExtensionRequired:                Self.StatusText := RSSIPExtensionRequired;
    SIPIntervalTooBrief:                 Self.StatusText := RSSIPIntervalTooBrief;
    SIPTemporarilyUnavailable:           Self.StatusText := RSSIPTemporarilyUnavailable;
    SIPCallLegOrTransactionDoesNotExist: Self.StatusText := RSSIPCallLegOrTransactionDoesNotExist;
    SIPLoopDetected:                     Self.StatusText := RSSIPLoopDetected;
    SIPTooManyHops:                      Self.StatusText := RSSIPTooManyHops;
    SIPAddressIncomplete:                Self.StatusText := RSSIPAddressIncomplete;
    SIPAmbiguous:                        Self.StatusText := RSSIPAmbiguous;
    SIPBusyHere:                         Self.StatusText := RSSIPBusyHere;
    SIPRequestTerminated:                Self.StatusText := RSSIPRequestTerminated;
    SIPNotAcceptableHere:                Self.StatusText := RSSIPNotAcceptableHere;
    SIPRequestPending:                   Self.StatusText := RSSIPRequestPending;
    SIPUndecipherable:                   Self.StatusText := RSSIPUndecipherable;
    SIPInternalServerError:              Self.StatusText := RSSIPInternalServerError;
    SIPNotImplemented:                   Self.StatusText := RSSIPNotImplemented;
    SIPBadGateway:                       Self.StatusText := RSSIPBadGateway;
    SIPServiceUnavailable:               Self.StatusText := RSSIPServiceUnavailable;
    SIPServerTimeOut:                    Self.StatusText := RSSIPServerTimeOut;
    SIPSIPVersionNotSupported:           Self.StatusText := RSSIPSIPVersionNotSupported;
    SIPMessageTooLarge:                  Self.StatusText := RSSIPMessageTooLarge;
    SIPBusyEverywhere:                   Self.StatusText := RSSIPBusyEverywhere;
    SIPDecline:                          Self.StatusText := RSSIPDecline;
    SIPDoesNotExistAnywhere:             Self.StatusText := RSSIPDoesNotExistAnywhere;
    SIPNotAcceptableGlobal:              Self.StatusText := RSSIPNotAcceptableGlobal;
  else
    Self.StatusText := RSSIPUnknownResponseCode;
  end;
end;

//******************************************************************************
//* TIdSipParser                                                               *
//******************************************************************************
//* TIdSipParser Public methods ************************************************

class function TIdSipParser.IsIPv6Reference(const Token: String): Boolean;
begin
  Result := (Copy(Token, 1, 1) = '[')
        and (Copy(Token, Length(Token), 1) = ']')
        and TIdIPAddressParser.IsIPv6Address(Copy(Token, 2, Length(Token) - 2));
end;

class function TIdSipParser.IsMethod(Method: String): Boolean;
begin
  Result := Self.IsToken(Method);
end;

class function TIdSipParser.IsQuotedString(const Token: String): Boolean;
var
  S: String;
begin
  Result := Token <> '';

  if Result then begin
    Result := ((Copy(Token, 1, 1) = '"')
              and (Copy(Token, Length(Token), 1) = '"')
              and DecodeQuotedStr(Copy(Token, 2, Length(Token) - 2), S));
  end;
end;

class function TIdSipParser.IsQValue(const Token: String): Boolean;
begin
  try
    StrToQValue(Token);
    Result := true;
  except
    Result := false;
  end;
end;

class function TIdSipParser.IsScheme(const Scheme: String): Boolean;
var
  I: Integer;
begin
  Result := Scheme <> '';

  if Result then begin
    Result := Result and Self.IsLetter(Scheme[1]);

    I := 2;
    while (I <= Length(Scheme)) and Result do begin
      Result := Result
            and (Self.IsAlphaNumeric(Scheme[I])
                 or (Scheme[I] in ['+', '-', '.']));
      Inc(I);
    end;
  end;
end;

class function TIdSipParser.IsSipVersion(Version: String): Boolean;
var
  Token: String;
begin
  Token := Fetch(Version, '/');
  Result := IsEqual(Token, SipName);

  if (Result) then begin
    Token := Fetch(Version, '.');

    Result := Result and Self.IsNumber(Token);
    Result := Result and Self.IsNumber(Version);
  end;
end;

class function TIdSipParser.IsToken(const Token: String): Boolean;
var
  I: Integer;
begin
  Result := Token <> '';

  if Result then
    for I := 1 to Length(Token) do begin
      Result := Result and (Token[I] in LegalTokenChars);
      if not Result then Break;
    end;
end;

class function TIdSipParser.IsTransport(const Token: String): Boolean;
begin
  try
    StrToTransport(Token);
    Result := true;
  except
    Result := false;
  end;
end;

class function TIdSipParser.IsWord(const Token: String): Boolean;
var
  I: Integer;
begin
  Result := Token <> '';

  if Result then
    for I := 1 to Length(Token) do begin
      Result := Result and (Token[I] in LegalWordChars);

      if not Result then Break;
    end;
end;

function TIdSipParser.GetHeaderName(Header: String): String;
begin
  Result := Trim(Fetch(Header, ':'));
end;

function TIdSipParser.GetHeaderNumberValue(const Msg: TIdSipMessage;
                                           const Header: String): Cardinal;
var
  Name:  String;
  Value: String;
  E:     Integer;
begin
  Name  := Self.GetHeaderName(Header);
  Value := Self.GetHeaderValue(Header);
  Val(Value, Result, E);
  if (E <> 0) then
    Self.FailParse(Msg, Format(MalformedToken, [Name, Header]));
end;

function TIdSipParser.GetHeaderValue(Header: String): String;
begin
  if (IndyPos(':', Header) = 0) then
    Result := ''
  else begin
    Result := Header;
    Fetch(Result, ':');
    Result := Trim(Result);
  end;
end;

function TIdSipParser.ParseAndMakeMessage: TIdSipMessage;
var
  FirstLine: String;
  FirstToken: String;
begin
  if not Self.Eof then begin
    FirstLine := Self.PeekLine;
    FirstToken := Fetch(FirstLine);
    FirstToken := Fetch(FirstToken, '/');

    // We can do this safely because we know a SIP response starts with "SIP/",
    // and a Method can't contain the character "/".
    Result := Self.CreateResponseOrRequest(FirstToken);
    try
      Self.ParseMessage(Result);
    except
      Result.Free;

      raise;
    end;
  end
  else
    raise EParserError.Create(EmptyInputStream);
end;

function TIdSipParser.ParseAndMakeMessage(const Src: String): TIdSipMessage;
var
  OriginalSrc: TStream;
  S:           TStringStream;
begin
  OriginalSrc := Self.Source;
  try
    S := TStringStream.Create(Src);
    try
      Self.Source := S;

      Result := Self.ParseAndMakeMessage;
      try
        Result.Body := S.ReadString(Result.ContentLength);
      except
        Result.Free;

        raise;
      end;
    finally
      S.Free;
    end;
  finally
    Self.Source := OriginalSrc;
  end;
end;

function TIdSipParser.ParseAndMakeMessage(const Src: String;
                                          const MessageType: TIdSipMessageClass): TIdSipMessage;
var
  OriginalSrc: TStream;
  S:           TStringStream;
begin
  OriginalSrc := Self.Source;
  try
    S := TStringStream.Create(Src);
    try
      Self.Source := S;

      Result := MessageType.Create;
      try
        Self.ParseMessage(Result);
        Result.Body := S.ReadString(Result.ContentLength);
      except
        Result.Free;

        raise;
      end;
    finally
      S.Free;
    end;
  finally
    Self.Source := OriginalSrc;
  end;
end;

function TIdSipParser.ParseAndMakeRequest: TIdSipRequest;
begin
  Result := TIdSipRequest.Create;
  try
    Self.ParseRequest(Result);
  except
    Result.Free;

    raise;
  end;
end;

function TIdSipParser.ParseAndMakeRequest(const Src: String): TIdSipRequest;
begin
  Result := Self.ParseAndMakeMessage(Src, TIdSipRequest) as TIdSipRequest;
end;

function TIdSipParser.ParseAndMakeResponse: TIdSipResponse;
begin
  Result := TIdSipResponse.Create;
  try
    Self.ParseResponse(Result);
  except
    Result.Free;

    raise;
  end;
end;

function TIdSipParser.ParseAndMakeResponse(const Src: String): TIdSipResponse;
begin
  Result := Self.ParseAndMakeMessage(Src, TIdSipResponse) as TIdSipResponse;
end;

procedure TIdSipParser.ParseMessage(const Msg: TIdSipMessage);
begin
  try
    Msg.Accept(Self);
  except
    on E: EParserError do begin
      Self.DoOnParseError(E.Message);
      raise;
    end;
  end;
end;

procedure TIdSipParser.ParseRequest(const Request: TIdSipRequest);
begin
  Self.InitializeMessage(Request);

  if not Self.Eof then begin
    Self.ResetCurrentLine;
    Self.ParseRequestLine(Request);
    Self.ParseHeaders(Request);
  end;

  Self.CheckRequiredRequestHeaders(Request);
  Self.CheckContentLengthContentType(Request);
  Self.CheckCSeqMethod(Request);
end;

procedure TIdSipParser.ParseResponse(const Response: TIdSipResponse);
begin
  Self.InitializeMessage(Response);

  if not Self.Eof then begin
    Self.ResetCurrentLine;
    Self.ParseStatusLine(Response);
    Self.ParseHeaders(Response);
  end;

  Self.CheckContentLengthContentType(Response);
//  Self.CheckRequiredResponseHeaders(Response);
end;

procedure TIdSipParser.VisitRequest(Request: TIdSipRequest);
begin
  Self.ParseRequest(Request);
end;

procedure TIdSipParser.VisitResponse(Response: TIdSipResponse);
begin
  Self.ParseResponse(Response);
end;

//* TIdSipParser Private methods ***********************************************

procedure TIdSipParser.AddHeader(Msg: TIdSipMessage; Header: String);
var
  Name: String;
  S:    String;
begin
  S := Header;
  Name := Trim(Fetch(S, ':'));
  Name := TIdSipHeaders.CanonicaliseName(Name);

  Msg.AddHeader(Name).Value := Trim(S);
end;

procedure TIdSipParser.CheckContentLengthContentType(Msg: TIdSipMessage);
begin
  if (Msg.ContentLength > 0) and (Msg.ContentType = '') then
    Self.FailParse(Msg, MissingContentType);
end;

procedure TIdSipParser.CheckCSeqMethod(Request: TIdSipRequest);
begin
  if (Request.CSeq.Method <> Request.Method) then
    Self.FailParse(Request, CSeqMethodMismatch);
end;

procedure TIdSipParser.CheckRequiredRequestHeaders(Msg: TIdSipMessage);
var
  Request: TIdSipRequest;
begin
  Self.CheckRequiredResponseHeaders(Msg);

  Request := Msg as TIdSipRequest;
  if not Request.HasHeader(MaxForwardsHeader) then
    Request.MaxForwards := Request.DefaultMaxForwards;

//  if not Msg.HasHeader(MaxForwardsHeader) then
//    Self.FailParse(Msg, MissingMaxForwards);
end;

procedure TIdSipParser.CheckRequiredResponseHeaders(Msg: TIdSipMessage);
begin
  if not Msg.HasHeader(CallIDHeaderFull) then
    Self.FailParse(Msg, MissingCallID);

  if not Msg.HasHeader(CSeqHeader) then
    Self.FailParse(Msg, MissingCSeq);

  if not Msg.HasHeader(FromHeaderFull) then
    Self.FailParse(Msg, MissingFrom);

  if not Msg.HasHeader(ToHeaderFull) then
    Self.FailParse(Msg, MissingTo);

  if not Msg.HasHeader(ViaHeaderFull) then
    Self.FailParse(Msg, MissingVia);
end;

function TIdSipParser.CreateResponseOrRequest(const Token: String): TIdSipMessage;
begin
  if (Token = SipName) then
    Result := TIdSipResponse.Create
  else
    Result := TIdSipRequest.Create;
end;

procedure TIdSipParser.DoOnParseError(const Reason: String);
var
  S: TStringStream;
begin
  Self.Source.Seek(0, soFromBeginning);
  S := TStringStream.Create('');
  try
    S.CopyFrom(Self.Source, 0);

    if Assigned(Self.OnParserError) then
      Self.OnParserError(S.DataString, Reason);
  finally
    S.Free;
  end;
end;

procedure TIdSipParser.FailParse(Msg: TIdSipMessage; const Reason: String);
begin
  raise Msg.MalformedException.Create(Reason, StreamToStr(Self.Source));
end;

procedure TIdSipParser.InitializeMessage(Msg: TIdSipMessage);
begin
  Msg.ClearHeaders;
  Msg.SipVersion := '';
end;


procedure TIdSipParser.ParseCompoundHeader(Msg: TIdSipMessage;
                                           const Header: String;
                                           Parms: String);
begin
  while (Parms <> '') do
    Msg.AddHeader(Header).Value := Fetch(Parms, ',');
end;

procedure TIdSipParser.ParseHeader(Msg: TIdSipMessage; const Header: String);
begin
  try
    if TIdSipHeaders.IsCompoundHeader(Header) then
      Self.ParseCompoundHeader(Msg, Self.GetHeaderName(Header), Self.GetHeaderValue(Header))
    else
      Self.AddHeader(Msg, Header);
  except
    on E: EBadHeader do
      Self.FailParse(Msg, Format(MalformedToken, [E.Message, Header]));
  end;
end;

procedure TIdSipParser.ParseHeaders(Msg: TIdSipMessage);
var
  FoldedHeader: String;
  Line:         String;
begin
  FoldedHeader := Self.ReadLn;
  if (FoldedHeader <> '') then begin
    Line := Self.ReadLn;
    while (Line <> '') do begin
      if (Line[1] in [' ', #9]) then begin
        FoldedHeader := FoldedHeader + ' ' + Trim(Line);
        Line := Self.ReadLn;
      end
      else begin
        Self.ParseHeader(Msg, FoldedHeader);
        FoldedHeader := Line;
        Line := Self.ReadLn;
      end;
    end;
    if (FoldedHeader <> '') then
      Self.ParseHeader(Msg, FoldedHeader);
  end;
end;

procedure TIdSipParser.ParseRequestLine(Request: TIdSipRequest);
var
  Line:   String;
  Tokens: TStrings;
  URI:    String;
begin
  // chew up leading blank lines (Section 7.5)
  Line := Self.ReadFirstNonBlankLine;

  Tokens := TStringList.Create;
  try
    BreakApart(Line, ' ', Tokens);

    if (Tokens.Count > 3) then
      Self.FailParse(Request, RequestUriNoSpaces)
    else if (Tokens.Count < 3) then
      Self.FailParse(Request, Format(MalformedToken, ['Request-Line', Line]));

    Request.Method := Tokens[0];
    // we want to check the Method
    if not Self.IsMethod(Request.Method) then
      Self.FailParse(Request, Format(MalformedToken, ['Method', Request.Method]));

    URI := Tokens[1];

    if (URI <> '') and (URI[1] = '<') and (URI[Length(URI)] = '>') then
      Self.FailParse(Request, RequestUriNoAngleBrackets);

    Request.RequestUri.URI := URI;

    Request.SIPVersion := Tokens[2];

    if not Self.IsSipVersion(Request.SIPVersion) then
      Self.FailParse(Request, Format(InvalidSipVersion, [Request.SIPVersion]));
  finally
    Tokens.Free;
  end;
end;

procedure TIdSipParser.ParseStatusLine(Response: TIdSipResponse);
var
  Line:   String;
  StatusCode: String;
begin
  // chew up leading blank lines (Section 7.5)
  Line := Self.ReadFirstNonBlankLine;

  Response.SIPVersion := Fetch(Line);
  if not Self.IsSipVersion(Response.SIPVersion) then
    Self.FailParse(Response, Format(InvalidSipVersion, [Response.SIPVersion]));

  StatusCode := Fetch(Line);
  if not Self.IsNumber(StatusCode) then
    Self.FailParse(Response, Format(InvalidStatusCode, [StatusCode]));

  Response.StatusCode := StrToIntDef(StatusCode, BadStatusCode);

  Response.StatusText := Line;
end;

function TIdSipParser.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := 0;
end;

function TIdSipParser._AddRef: Integer;
begin
  Result := -1;
end;

function TIdSipParser._Release: Integer;
begin
  Result := -1;
end;

//******************************************************************************
//* EBadMessage                                                                *
//******************************************************************************
//* EBadMessage Public methods *************************************************

constructor EBadMessage.Create(const Msg: String;
                               const RawMessage: String);
begin
  inherited Create(Msg);
  Self.RawMessage := RawMessage;
end;

initialization
finalization
  GCanonicalHeaderNames.Free;
  GIdSipHeadersMap.Free;
end.
