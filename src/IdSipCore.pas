{
  (c) 2004 Directorate of New Technologies, Royal National Institute for Deaf people (RNID)

  The RNID licence covers this unit. Read the licence at:
      http://www.ictrnid.org.uk/docs/gw/rnid_license.txt

  This unit contains code written by:
    * Frank Shearar
}
unit IdSipCore;

// Some overarching principles followed in this implementation of a SIP/2.0
// (RFC 3261) stack:
// * We rely on short-circuited evaluation of Boolean expressions.
// * We manually manage the lifetime of all objects. We do NOT use reference
//   counting for objects that implement interfaces.
// * We use Value Objects when possible.
// * If an object A receives some object B that it expects to store as data
//   then A must store a COPY of B. Typical objects are: TIdSipURI,
//   TIdSipDialogID, TIdSipMessage.
// * Each layer has references to the layers beneath it. We try to make each layer
//   aware of ONLY the layer immediately below it, but that's not always
//   possible. We NEVER let a lower layer know about layers above it. Thus, the
//   transport layer DOES NOT know about transactions, etc.
// * We propogate messages up the stack using Events or Listeners, and method
//   calls to propogate messages down the stack. We give preference to the more
//   flexible Listeners.
// * We avoid typecasting as much as possible by using polymorphism and, in
//   certain situations where polymorphism can't cut it, the Visitor pattern.
// * TObjectLists always manage the lifetime of the objects they contain. Except
//   in the case of Transports in the Dispatcher.

interface

uses
  Classes, Contnrs, IdSipDialog, IdSipDialogID, IdException,
  IdInterfacedObject, IdNotification, IdObservable, IdSipAuthentication,
  IdSipMessage, IdSipRegistration, IdSipTimer, IdSipTransaction,
  IdSipTransport, SyncObjs;

type
  TIdSipAction = class;
  TIdSipOutboundOptions = class;
  TIdSipOutboundRegistration = class;
  TIdSipSession = class;
  TIdSipSessionEvent = procedure(Session: TIdSipSession) of object;

  // I provide a protocol for generic Actions.
  //
  // You can use OnAuthenticationChallenge to authenticate to a proxy (or
  // registrar or user agent server). Note that we cannot distinguish between
  // (1) you contactingthe proxy/registrar for the first time and it asking
  // for credentials, and (2) you offering invalid credentials.
  IIdSipActionListener = interface
    ['{C3255325-A52E-46FF-9C21-478880FB350A}']
    procedure OnAuthenticationChallenge(Action: TIdSipAction;
                                        Challenge: TIdSipResponse;
                                        var Password: String);
  end;

  IIdSipOptionsListener = interface(IIdSipActionListener)
    ['{3F2ED4DF-4854-4255-B156-F4581AEAEDA3}']
    procedure OnFailure(OptionsAgent: TIdSipOutboundOptions;
                        Response: TIdSipResponse;
                        const Reason: String);
    procedure OnSuccess(OptionsAgent: TIdSipOutboundOptions;
                        Response: TIdSipResponse);
  end;

  // I provide a protocol for using a registrar. You send a REGISTER, and
  // listen for the events below.
  //
  // OnFailure and OnSuccess, apart from the obvious, tell you that the
  // registration agent has terminated, and that you should remove all
  // of your references to it.
  IIdSipRegistrationListener = interface(IIdSipActionListener)
    ['{D3FA9A3D-ED8A-48D3-8068-38E8F9EE2140}']
    procedure OnFailure(RegisterAgent: TIdSipOutboundRegistration;
                        CurrentBindings: TIdSipContacts;
                        const Reason: String);
    procedure OnSuccess(RegisterAgent: TIdSipOutboundRegistration;
                        CurrentBindings: TIdSipContacts);
  end;

  // I am the protocol of things that listen for Sessions:
  // * OnNewSession tells us that someone wants to talk to us - we may refuse or
  //   allow the session.
  // * OnSessionEstablished tells us when a session has been fully established.
  // * OnSessionEnded tells us when the session's finished. This could be
  //   because someone hung up, or because the outbound call failed (the request
  //   timed out, a transport error occurec, etc). OnSessionEnded lets us clean
  //   up. The Session referenced becomes invalid after this point. In other
  //   words, you'd better say goodbye to the Session in your implementation of
  //   this method. Accessing your reference to the Session will probably fail
  //   with an access violation.
  IIdSipSessionListener = interface(IIdSipActionListener)
    ['{59B3C476-D3CA-4C5E-AA2B-2BB587A5A716}']
    procedure OnEndedSession(Session: TIdSipSession;
                             const Reason: String);
    procedure OnEstablishedSession(Session: TIdSipSession);
    procedure OnModifiedSession(Session: TIdSipSession;
                                Invite: TIdSipRequest);
  end;

  TIdSipInboundSession = class;

  IIdSipUserAgentListener = interface
    ['{E365D17F-054B-41AB-BB18-0C339715BFA3}']
    procedure OnDroppedUnmatchedResponse(Response: TIdSipResponse;
                                         Receiver: TIdSipTransport);
    procedure OnInboundCall(Session: TIdSipInboundSession);
  end;

  TIdSipUserAgentReaction =
    (uarAccept,
     uarBadAuthorization,
     uarBadRequest,
     uarExpireTooBrief,
     uarForbidden,
     uarLoopDetected,
     uarMissingContact,
     uarNotFound,
     uarUnsupportedExtension,
     uarTooManyVias,
     uarUnauthorized,
     uarUnsupportedContentEncoding,
     uarUnsupportedContentLanguage,
     uarUnsupportedContentType,
     uarUnsupportedMethod,
     uarUnsupportedScheme,
     uarUnsupportedSipVersion);

  // TODO: there's redundance with this Hostname, and the Hostnames of the
  // transports attached to this core. It's not clear how to set up the
  // hostnames and bindings of the stack.
  TIdSipAbstractCore = class(TIdInterfacedObject,
                             IIdSipUnhandledMessageListener)
  private
    fAuthenticator:         TIdSipAbstractAuthenticator;
    fDispatcher:            TIdSipTransactionDispatcher;
    fHostName:              String;
    fRealm:                 String;
    fRequireAuthentication: Boolean;
    fUserAgentName:         String;
    Observed:               TIdObservable;

    function  DefaultHostName: String;
    procedure OnReceiveUnhandledRequest(Request: TIdSipRequest;
                                        Receiver: TIdSipTransport);
    procedure OnReceiveUnhandledResponse(Response: TIdSipResponse;
                                         Receiver: TIdSipTransport);
    procedure RejectBadAuthorization(Request: TIdSipRequest);
    procedure SetDispatcher(Value: TIdSipTransactionDispatcher);
  protected
    procedure ActOnRequest(Request: TIdSipRequest;
                           Receiver: TIdSipTransport); virtual;
    procedure ActOnResponse(Response: TIdSipResponse;
                           Receiver: TIdSipTransport); virtual;
    function  AuthenticationHeader: String; virtual;
    function  AuthenticationHeaderValue: String; virtual;
    function  AuthenticationStatusCode: Cardinal; virtual;
    function  HasAuthorization(Request: TIdSipRequest): Boolean; virtual;
    procedure NotifyOfChange;
    procedure OnReceiveRequest(Request: TIdSipRequest;
                               Receiver: TIdSipTransport); virtual;
    procedure OnReceiveResponse(Response: TIdSipResponse;
                                Receiver: TIdSipTransport); virtual;
    procedure PrepareResponse(Response: TIdSipResponse;
                              Request: TIdSipRequest);
    procedure RejectBadRequest(Request: TIdSipRequest;
                               const Reason: String);
    procedure RejectRequest(Reaction: TIdSipUserAgentReaction;
                            Request: TIdSipRequest); virtual;
    procedure RejectRequestUnauthorized(Request: TIdSipRequest); virtual;
    function  WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction; virtual;
    function  WillAcceptResponse(Response: TIdSipResponse): TIdSipUserAgentReaction; virtual;
  public
    constructor Create; virtual;
    destructor  Destroy; override;

    procedure AddObserver(const Listener: IIdObserver);
    function  CreateRequest(Dest: TIdSipAddressHeader): TIdSipRequest; overload; virtual; abstract;
    function  CreateRequest(Dialog: TIdSipDialog): TIdSipRequest; overload; virtual; abstract;
    function  CreateResponse(Request: TIdSipRequest;
                             ResponseCode: Cardinal): TIdSipResponse; virtual;
    function  NextCallID: String;
    function  NextTag: String;
    procedure RemoveObserver(const Listener: IIdObserver);
    procedure SendRequest(Request: TIdSipRequest);
    procedure SendResponse(Response: TIdSipResponse);

    property Authenticator:         TIdSipAbstractAuthenticator read fAuthenticator write fAuthenticator;
    property Dispatcher:            TIdSipTransactionDispatcher read fDispatcher write SetDispatcher;
    property HostName:              String                      read fHostName write fHostName;
    property Realm:                 String                      read fRealm write fRealm;
    property RequireAuthentication: Boolean                     read fRequireAuthentication write fRequireAuthentication;
    property UserAgentName:         String                      read fUserAgentName write fUserAgentName;
  end;

  // I represent the heart of a User Agent. We split User Agent functionality
  // into multiple levels because some SIP entities (like registrars) behave
  // very similarly to "normal" User Agents. In fact, we can regard a registrar
  // as simply a User Agent that responds to REGISTER methods.

  // I provide the canonical place to reject messages that have correct syntax
  // but that we don't or can't accept. This includes unsupported SIP versions,
  // unrecognised methods, etc.
  TIdSipAbstractUserAgent = class(TIdSipAbstractCore)
  private
    fAllowedContentTypeList: TStrings;
    fAllowedLanguageList:    TStrings;
    fAllowedMethodList:      TStrings;
    fAllowedSchemeList:      TStrings;
    fFrom:                   TIdSipFromHeader;

    function  ConvertToHeader(ValueList: TStrings): String;
    function  GetFrom: TIdSipFromHeader;
    procedure RejectRequestMethodNotAllowed(Request: TIdSipRequest);
    procedure RejectRequestUnknownContentEncoding(Request: TIdSipRequest);
    procedure RejectRequestUnknownContentLanguage(Request: TIdSipRequest);
    procedure RejectRequestUnknownContentType(Request: TIdSipRequest);
    procedure RejectUnsupportedSipVersion(Request: TIdSipRequest);
    procedure SetFrom(Value: TIdSipFromHeader);
  protected
    procedure AddLocalHeaders(OutboundRequest: TIdSipRequest); virtual;
    procedure RejectRequest(Reaction: TIdSipUserAgentReaction;
                            Request: TIdSipRequest); override;
    procedure RejectRequestBadExtension(Request: TIdSipRequest);
    function  WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction; override;

    property AllowedContentTypeList: TStrings read fAllowedContentTypeList;
    property AllowedLanguageList:    TStrings read fAllowedLanguageList;
    property AllowedMethodList:      TStrings read fAllowedMethodList;
    property AllowedSchemeList:      TStrings read fAllowedSchemeList;
  public
    constructor Create; override;
    destructor  Destroy; override;

    procedure AddAllowedContentType(const MimeType: String);
    procedure AddAllowedLanguage(const LanguageID: String);
    procedure AddAllowedMethod(const Method: String);
    procedure AddAllowedScheme(const Scheme: String);
    function  AllowedContentTypes: String;
    function  AllowedEncodings: String;
    function  AllowedExtensions: String;
    function  AllowedLanguages: String;
    function  AllowedMethods: String;
    function  AllowedSchemes: String;
    function  CreateRequest(Dest: TIdSipAddressHeader): TIdSipRequest; overload; override;
    function  HasUnknownContentEncoding(Request: TIdSipRequest): Boolean;
    function  HasUnknownContentLanguage(Request: TIdSipRequest): Boolean;
    function  HasUnknownContentType(Request: TIdSipRequest): Boolean;
    function  IsExtensionAllowed(const Extension: String): Boolean;
    function  IsMethodAllowed(const Method: String): Boolean;
    function  IsSchemeAllowed(const Scheme: String): Boolean;
    function  NextBranch: String;
    function  NextInitialSequenceNo: Cardinal;
    procedure RemoveAllowedMethod(const Method: String);
    procedure ReturnResponse(Request: TIdSipRequest;
                             Reason: Cardinal);

    property From: TIdSipFromHeader read GetFrom write SetFrom;
  end;

  // I keep track of information a User Agent needs when making a REGISTER to
  // a particular registrar.
  TIdSipRegistrationInfo = class(TObject)
  private
    fCallID:     String;
    fRegistrar:  TIdSipUri;
    fSequenceNo: Cardinal;
  public
    constructor Create;
    destructor  Destroy; override;

    property CallID:     String    read fCallID write fCallID;
    property Registrar:  TIdSipUri read fRegistrar;
    property SequenceNo: Cardinal  read fSequenceNo write fSequenceNo;
  end;


  TIdSipInboundOptions = class;
  TIdSipInboundRegistration = class;
  TIdSipOutboundSession = class;

  // I (usually) represent a human being in the SIP network. I:
  // * inform any listeners when new sessions become established, modified or
  //   terminated;
  // * allow my users to make outgoing "calls";
  // * clean up established Sessions
  TIdSipUserAgentCore = class(TIdSipAbstractUserAgent)
  private
    ActionLock:            TCriticalSection;
    Actions:               TObjectList;
    fBindingDB:            TIdSipAbstractBindingDatabase;
    fContact:              TIdSipContactHeader;
    fDoNotDisturb:         Boolean;
    fDoNotDisturbMessage:  String;
    fHasProxy:             Boolean;
    fMinimumExpiryTime:    Cardinal; // in seconds
    fProxy:                TIdSipUri;
    KnownRegistrars:       TObjectList;
    UserAgentListeners:    TIdNotificationList;

    function  ActionAt(Index: Integer): TIdSipAction;
    function  AddFork(RootSession: TIdSipOutboundSession;
                      Response: TIdSipResponse): TIdSipOutboundSession;
    function  AddInboundOptions(Options: TIdSipRequest): TIdSipInboundOptions;
    function  AddInboundRegistration(Reg: TIdSipRequest): TIdSipInboundRegistration;
    function  AddInboundSession(Invite: TIdSipRequest;
                                UsingSecureTransport: Boolean): TIdSipInboundSession;
    procedure AddKnownRegistrar(Registrar: TIdSipUri;
                                const CallID: String;
                                SequenceNo: Cardinal);
    function  AddOutboundOptions: TIdSipOutboundOptions;
    function  AddOutboundSession: TIdSipOutboundSession;
    function  AddOutboundRegistration: TIdSipOutboundRegistration;
    function  CallIDFor(Registrar: TIdSipUri): String;
    function  DefaultFrom: String;
    function  DefaultUserAgent: String;
    function  FindAction(Msg: TIdSipMessage): TIdSipAction;
    function  ForkCall(Response: TIdSipResponse): TIdSipOutboundSession;
    function  GetContact: TIdSipContactHeader;
    function  GetDefaultRegistrationExpiryTime: Cardinal;
    function  IndexOfRegistrar(Registrar: TIdSipUri): Integer;
    function  KnowsRegistrar(Registrar: TIdSipUri): Boolean;
    function  NextSequenceNoFor(Registrar: TIdSipUri): Cardinal;
    procedure NotifyOfInboundCall(Session: TIdSipInboundSession);
    procedure NotifyOfDroppedResponse(Response: TIdSipResponse;
                                      Receiver: TIdSipTransport);
    procedure OnInboundSessionExpire(Sender: TObject);
    function  RegistrarAt(Index: Integer): TIdSipRegistrationInfo;
    function  ResponseForInvite: Cardinal;
    procedure SetContact(Value: TIdSipContactHeader);
    procedure SetDefaultRegistrationExpiryTime(Value: Cardinal);
    procedure SetProxy(Value: TIdSipUri);
    procedure TurnIntoInvite(OutboundRequest: TIdSipRequest;
                             const Offer: String;
                             const OfferMimeType: String);
  protected
    procedure ActOnRequest(Request: TIdSipRequest;
                           Receiver: TIdSipTransport); override;
    procedure ActOnResponse(Response: TIdSipResponse;
                           Receiver: TIdSipTransport); override;
    procedure AddLocalHeaders(OutboundRequest: TIdSipRequest); override;
    procedure OnReceiveRequest(Request: TIdSipRequest;
                               Receiver: TIdSipTransport); override;
    procedure OnReceiveResponse(Response: TIdSipResponse;
                                Receiver: TIdSipTransport); override;
    procedure RejectRequest(Reaction: TIdSipUserAgentReaction;
                            Request: TIdSipRequest); override;
    function  WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction; override;
  public
    constructor Create; override;
    destructor  Destroy; override;

    procedure AddUserAgentListener(const Listener: IIdSipUserAgentListener);
    function  Call(Dest: TIdSipAddressHeader;
                   const InitialOffer: String;
                   const MimeType: String): TIdSipOutboundSession;
    function  CreateAck(Dialog: TIdSipDialog): TIdSipRequest;
    function  CreateBye(Dialog: TIdSipDialog): TIdSipRequest;
    function  CreateInvite(Dest: TIdSipAddressHeader;
                           const Body: String;
                           const MimeType: String): TIdSipRequest;
    function  CreateOptions(Dest: TIdSipAddressHeader): TIdSipRequest;
    function  CreateRegister(Registrar: TIdSipToHeader): TIdSipRequest;
    function  CreateReInvite(Dialog: TIdSipDialog;
                             const Body: String;
                             const MimeType: String): TIdSipRequest;
    function  CreateRequest(Dialog: TIdSipDialog): TIdSipRequest; overload; override;
    function  CreateResponse(Request: TIdSipRequest;
                             ResponseCode: Cardinal): TIdSipResponse; override;
    function  CurrentRegistrationWith(Registrar: TIdSipUri): TIdSipOutboundRegistration;
    procedure TerminateAllCalls;
    function  OptionsCount: Integer;
    function  QueryOptions(Server: TIdSipAddressHeader): TIdSipOutboundOptions;
    function  RegisterWith(Registrar: TIdSipUri): TIdSipOutboundRegistration;
    function  RegistrationCount: Integer;
    procedure RemoveAction(Action: TIdSipAction);
    procedure RemoveUserAgentListener(const Listener: IIdSipUserAgentListener);
    function  SessionCount: Integer;
    function  UnregisterFrom(Registrar: TIdSipUri): TIdSipOutboundRegistration;
    function  Username: String;

    property BindingDB:                     TIdSipAbstractBindingDatabase read fBindingDB write fBindingDB;
    property Contact:                       TIdSipContactHeader           read GetContact write SetContact;
    property DoNotDisturb:                  Boolean                       read fDoNotDisturb write fDoNotDisturb;
    property DoNotDisturbMessage:           String                        read fDoNotDisturbMessage write fDoNotDisturbMessage;
    property HasProxy:                      Boolean                       read fHasProxy write fHasProxy;
    property Proxy:                         TIdSipUri                     read fProxy write SetProxy;
    property DefaultRegistrationExpiryTime: Cardinal                      read GetDefaultRegistrationExpiryTime write SetDefaultRegistrationExpiryTime;
    property MinimumExpiryTime:             Cardinal                      read fMinimumExpiryTime write fMinimumExpiryTime;
  end;

  TIdSipProcedure = procedure(ObjectOrIntf: Pointer) of object;

  // I represent an asynchronous message send between SIP entities - INVITEs,
  // REGISTERs and the like - where we care what the remote end answers.
  // With CANCELs and BYEs, for instance, we don't care how the remote end
  // answers.
  TIdSipAction = class(TIdInterfacedObject)
  private
    fCurrentRequest: TIdSipRequest;
    fIsTerminated:   Boolean;
    NonceCount:      Cardinal;
    UA:              TIdSipUserAgentCore;

    function  AddAuthorizationHeader(ReAttempt: TIdSipRequest;
                                     Challenge: TIdSipResponse): TIdSipAuthorizationHeader;
    function  AuthenticateHeader(Challenge: TIdSipResponse): TIdSipAuthenticateHeader;
    procedure Authorize(Challenge: TIdSipResponse; AgainstProxy: Boolean);
    procedure AuthorizeAgainstProxy(Challenge: TIdSipResponse);
    procedure AuthorizeAgainstUser(Challenge: TIdSipResponse);
    function  GetUsername: String;
    procedure SetUsername(const Value: String);
  protected
    Listeners: TIdNotificationList;

    procedure ActionSucceeded(Response: TIdSipResponse); virtual;
    function  CreateNewAttempt(Challenge: TIdSipResponse): TIdSipRequest; virtual; abstract;
    procedure MarkAsTerminated; virtual;
    function  NotifyOfAuthenticationChallenge(Response: TIdSipResponse): String;
    procedure NotifyOfFailure(Response: TIdSipResponse); virtual;
    function  ReceiveFailureResponse(Response: TIdSipResponse): Boolean; virtual;
    function  ReceiveGlobalFailureResponse(Response: TIdSipResponse): Boolean; virtual;
    function  ReceiveOKResponse(Response: TIdSipResponse;
                                UsingSecureTransport: Boolean): Boolean; virtual;
    function  ReceiveProvisionalResponse(Response: TIdSipResponse;
                                         UsingSecureTransport: Boolean): Boolean; virtual;
    function  ReceiveRedirectionResponse(Response: TIdSipResponse;
                                         UsingSecureTransport: Boolean): Boolean; virtual;
    function  ReceiveServerFailureResponse(Response: TIdSipResponse): Boolean; virtual;
    procedure SendRequest(Request: TIdSipRequest); virtual;
    procedure SendResponse(Response: TIdSipResponse); virtual;
  public
    class function Method: String; virtual; abstract;

    constructor Create(UA: TIdSipUserAgentCore); virtual;
    destructor  Destroy; override;

    function  IsOptions: Boolean; virtual;
    function  IsRegistration: Boolean; virtual;
    function  IsSession: Boolean; virtual;
    function  Match(Msg: TIdSipMessage): Boolean; virtual;
    procedure ReceiveRequest(Request: TIdSipRequest); virtual;
    procedure ReceiveResponse(Response: TIdSipResponse;
                              UsingSecureTransport: Boolean); virtual;
    procedure Terminate; virtual;

    property CurrentRequest: TIdSipRequest read fCurrentRequest;
    property IsTerminated:   Boolean       read fIsTerminated;
    property Username:       String        read GetUsername write SetUsername;
  end;

  TIdSipActionListenerAuthenticationChallengeMethod = class(TIdMethod)
  private
    fAction:        TIdSipAction;
    fFirstPassword: String;
    fResponse:      TIdSipResponse;
  public
    procedure Run(const Subject: IInterface); override;

    property Action:        TIdSipAction   read fAction write fAction;
    property FirstPassword: String         read fFirstPassword write fFirstPassword;
    property Response:      TIdSipResponse read fResponse write fResponse;
  end;

  TIdSipActionClass = class of TIdSipAction;

  // As per section 13.3.1.4 of RFC 3261, a Session will resend a 2xx response
  // to an INVITE until it receives an ACK. Thus I provide an exponential
  // back-off timer starting with an interval of T1 milliseconds and capping
  // the interval at T2 milliseconds.
  TIdSipSessionTimer = class(TObject)
  private
    Lock:    TCriticalSection;
    T1:      Cardinal;
    T2:      Cardinal;
    Session: TIdSipInboundSession;
    Timer:   TIdSipTimer;

    procedure OnTimer(Sender: TObject);
  public
    constructor Create(Session: TIdSipInboundSession;
                       T1: Cardinal;
                       T2: Cardinal);
    destructor  Destroy; override;

    procedure Fire;
    procedure Start;
    procedure Stop;

    function Interval: Cardinal;
  end;

  TIdSipSessionMethod = class(TIdMethod)
  private
    fSession: TIdSipSession;
  public
    property Session: TIdSipSession read fSession write fSession;
  end;

  TIdSipEndedSessionMethod = class(TIdSipSessionMethod)
  private
    fReason:  String;
  public
    procedure Run(const Subject: IInterface); override;

    property Reason:  String        read fReason write fReason;
  end;

  TIdSipEstablishedSessionMethod = class(TIdSipSessionMethod)
  public
    procedure Run(const Subject: IInterface); override;
  end;

  TIdSipModifiedSessionMethod = class(TIdSipSessionMethod)
  private
    fRequest: TIdSipRequest;
  public
    procedure Run(const Subject: IInterface); override;

    property Request: TIdSipRequest read fRequest write fRequest;
  end;

  // I am a SIP session. As such, I represent both what my dialog represents
  // (a long-term relationship between two peers in a SIP network) and also
  // the media streams initiated between those peers.
  //
  // Note that when you call my Terminate method, my owning UserAgent will
  // destroy me, and your reference to me will no longer be valid. The same
  // thing goes for when I notify you that I have terminated via
  // OnEndedSession.
  TIdSipSession = class(TIdSipAction)
  private
    DialogLock:           TCriticalSection;
    fDialog:              TIdSipDialog;
    fReceivedAck:         Boolean;
    OpenTransactionLock:  TCriticalSection;
    OpenTransactions:     TObjectList;
    UsingSecureTransport: Boolean;

    procedure MarkAsTerminatedProc(ObjectOrIntf: Pointer);
    procedure NotifyOfModifiedSession(Invite: TIdSipRequest);
    procedure ProcessBye(Request: TIdSipRequest);
    procedure RejectOutOfOrderRequest(Request: TIdSipRequest);
    procedure RejectRequest(Request: TIdSipRequest);
    procedure TerminateOpenTransaction(Request: TIdSipRequest);
  protected
    FullyEstablished: Boolean;

    procedure ActionSucceeded(Response: TIdSipResponse); override;
    procedure AddOpenTransaction(Request: TIdSipRequest);
    function  CreateDialogIDFrom(Msg: TIdSipMessage): TIdSipDialogID; virtual; abstract;
    function  CreateNewAttempt(Challenge: TIdSipResponse): TIdSipRequest; override;
    function  GetInvite: TIdSipRequest; virtual;
    procedure MarkAsTerminated; override;
    procedure NotifyOfEndedSession(const Reason: String);
    procedure NotifyOfEstablishedSession;
    procedure NotifyOfFailure(Response: TIdSipResponse); override;
    procedure SendBye; virtual;
  public
    class function Method: String; override;

    constructor Create(UA: TIdSipUserAgentCore); override;
    destructor  Destroy; override;

    procedure AddSessionListener(const Listener: IIdSipSessionListener);
    function  IsEarly: Boolean;
    function  DialogEstablished: Boolean;
    function  IsInboundCall: Boolean; virtual; abstract;
    function  IsOutboundCall: Boolean;
    function  IsSession: Boolean; override;
    function  Match(Msg: TIdSipMessage): Boolean; override;
    procedure Modify(const Offer, ContentType: String);
    function  PendingTransactionCount: Integer;
    procedure ReceiveRequest(Request: TIdSipRequest); override;
    procedure RemoveSessionListener(const Listener: IIdSipSessionListener);

    property Dialog:      TIdSipDialog read fDialog;
    property ReceivedAck: Boolean      read fReceivedAck;
  end;

  TIdSipInboundSession = class(TIdSipSession)
  private
    LastResponse: TIdSipResponse;
    OkTimer:      TIdSipSessionTimer;

    function  CreateInboundDialog(Response: TIdSipResponse): TIdSipDialog;
    procedure TerminatePendingInvite;
  protected
    function  CreateDialogIDFrom(Msg: TIdSipMessage): TIdSipDialogID; override;
  public
    constructor Create(UA: TIdSipUserAgentCore;
                       Invite: TIdSipRequest;
                       UsingSecureTransport: Boolean); reintroduce; virtual;
    destructor  Destroy; override;

    function  AcceptCall(const Offer, ContentType: String): String;
    procedure ForwardCall(NewDestination: TIdSipAddressHeader);
    function  IsInboundCall: Boolean; override;
    procedure ReceiveRequest(Request: TIdSipRequest); override;
    procedure RejectCallBusy;
    procedure ResendLastResponse; virtual;
    procedure Terminate; override;
    procedure TimeOut;
  end;

  TIdSipOutboundSession = class(TIdSipSession)
  private
    InCall: Boolean;

    function  CreateOutboundDialog(Response: TIdSipResponse;
                                   UsingSecureTransport: Boolean): TIdSipDialog;
    procedure Initialize;
    procedure SendAck(Final: TIdSipResponse);
    procedure SendCancel;
    procedure TerminateAfterSendingCancel;
  protected
    function  CreateDialogIDFrom(Msg: TIdSipMessage): TIdSipDialogID; override;
    function  ReceiveOKResponse(Response: TIdSipResponse;
                                UsingSecureTransport: Boolean): Boolean; override;
    function  ReceiveProvisionalResponse(Response: TIdSipResponse;
                                         UsingSecureTransport: Boolean): Boolean; override;
    function  ReceiveRedirectionResponse(Response: TIdSipResponse;
                                         UsingSecureTransport: Boolean): Boolean; override;
    procedure SendBye; override;
  public
    constructor Create(UA: TIdSipUserAgentCore); overload; override;
    constructor Create(UA: TIdSipUserAgentCore;
                       Invite: TIdSipRequest); reintroduce; overload;

    procedure Call(Dest: TIdSipAddressHeader;
                   const InitialOffer: String;
                   const MimeType: String);
    procedure Cancel;
    function  CanForkOn(Response: TIdSipResponse): Boolean;
    function  Fork(OkResponse: TIdSipResponse): TIdSipOutboundSession;
    function  IsInboundCall: Boolean; override;
    procedure Terminate; override;
  end;

  TIdSipOptions = class(TIdSipAction)
  protected
    function CreateNewAttempt(Challenge: TIdSipResponse): TIdSipRequest; override;
  public
    class function Method: String; override;

    function  IsOptions: Boolean; override;
    procedure Terminate; override;
  end;

  TIdSipInboundOptions = class(TIdSipOptions)
  public
    constructor Create(UA: TIdSipUserAgentCore;
                       Options: TIdSipRequest); reintroduce;

    procedure ReceiveRequest(Request: TIdSipRequest); override;
  end;

  TIdSipOutboundOptions = class(TIdSipOptions)
  private
    procedure NotifyOfSuccess(Response: TIdSipResponse);
  protected
    procedure ActionSucceeded(Response: TIdSipResponse); override;
  public
    procedure AddListener(const Listener: IIdSipOptionsListener);
    procedure QueryOptions(Server: TIdSipAddressHeader);
    procedure RemoveListener(const Listener: IIdSipOptionsListener);
  end;

  TIdSipRegistration = class(TIdSipAction)
  protected
    function CreateNewAttempt(Challenge: TIdSipResponse): TIdSipRequest; override;
  public
    class function Method: String; override;

    function  IsRegistration: Boolean; override;
    procedure Terminate; override;
  end;

  TIdSipInboundRegistration = class(TIdSipRegistration)
  private
    function  AcceptRequest(Request: TIdSipRequest): Boolean;
    function  BindingDB: TIdSipAbstractBindingDatabase;
    procedure RejectExpireTooBrief(Request: TIdSipRequest);
    procedure RejectFailedRequest(Request: TIdSipRequest);
    procedure RejectForbidden(Request: TIdSipRequest);
    procedure RejectNotFound(Request: TIdSipRequest);
    procedure RejectRequest(Request: TIdSipRequest;
                            StatusCode: Cardinal);
  public
    constructor Create(UA: TIdSipUserAgentCore;
                       Reg: TIdSipRequest); reintroduce;

    procedure ReceiveRequest(Request: TIdSipRequest); override;
  end;

  // I piggyback on a transaction in a blocking I/O fashion to provide a UAC
  // with a way to register with a registrar. I take care of things like
  // doing stuff with error responses, asking for authentication, etc.
  //
  // It makes no sense to access me once my Transaction has terminated. In
  // other words once you've received notification of my success or failure,
  // erase your references to me.
  TIdSipOutboundRegistration = class(TIdSipRegistration)
  private
    Bindings: TIdSipContacts;

    function  CreateRegister(Registrar: TIdSipUri;
                             Bindings: TIdSipContacts): TIdSipRequest;
    procedure NotifyOfSuccess(Response: TIdSipResponse);
    procedure ReissueRequest(Registrar: TIdSipUri;
                             MinimumExpiry: Cardinal);
    procedure RetryWithoutExtensions(Registrar: TIdSipUri;
                                     Response: TIdSipResponse);
  protected
    procedure ActionSucceeded(Response: TIdSipResponse); override;
    procedure NotifyOfFailure(Response: TIdSipResponse); override;
    function  ReceiveFailureResponse(Response: TIdSipResponse): Boolean; override;
    function  ReceiveRedirectionResponse(Response: TIdSipResponse;
                                         UsingSecureTransport: Boolean): Boolean; override;
    procedure SendRequest(Request: TIdSipRequest); override;
  public
    constructor Create(UA: TIdSipUserAgentCore); override;
    destructor  Destroy; override;

    procedure AddListener(const Listener: IIdSipRegistrationListener);
    procedure FindCurrentBindings(Registrar: TIdSipUri);
    procedure RegisterWith(Registrar: TIdSipUri; Bindings: TIdSipContacts); overload;
    procedure RegisterWith(Registrar: TIdSipUri; Contact: TIdSipContactHeader); overload;
    procedure RemoveListener(const Listener: IIdSipRegistrationListener);
    procedure Unregister(Registrar: TIdSipUri);
  end;

  TIdSipRegistrationMethod = class(TIdMethod)
  private
    fCurrentBindings: TIdSipContacts;
    fRegistration:    TIdSipOutboundRegistration;
  public
    property CurrentBindings: TIdSipContacts             read fCurrentBindings write fCurrentBindings;
    property Registration:    TIdSipOutboundRegistration read fRegistration write fRegistration;
  end;

  TIdSipOptionsMethod = class(TIdMethod)
  private
    fOptions:  TIdSipOutboundOptions;
    fResponse: TIdSipResponse;
  public

    property Options:  TIdSipOutboundOptions read fOptions write fOptions;
    property Response: TIdSipResponse        read fResponse write fResponse;
  end;

  TIdSipOptionsFailureMethod = class(TIdSipOptionsMethod)
  private
    fReason: String;
  public
    procedure Run(const Subject: IInterface); override;

    property Reason: String read fReason write fReason;
  end;

  TIdSipOptionsSuccessMethod = class(TIdSipOptionsMethod)
  public
    procedure Run(const Subject: IInterface); override;
  end;

  TIdSipRegistrationFailedMethod = class(TIdSipRegistrationMethod)
  private
    fReason: String;
  public
    procedure Run(const Subject: IInterface); override;

    property Reason: String read fReason write fReason;
  end;

  TIdSipRegistrationSucceededMethod = class(TIdSipRegistrationMethod)
  public
    procedure Run(const Subject: IInterface); override;
  end;

  TIdSipUserAgentDroppedUnmatchedResponseMethod = class(TIdMethod)
  private
    fReceiver: TIdSipTransport;
    fResponse: TIdSipResponse;
  public
    procedure Run(const Subject: IInterface); override;

    property Receiver: TIdSipTransport read fReceiver write fReceiver;
    property Response: TIdSipResponse  read fResponse write fResponse;
  end;

  TIdSipUserAgentInboundCallMethod = class(TIdMethod)
  private
    fSession: TIdSipInboundSession;
  public
    procedure Run(const Subject: IInterface); override;

    property Session: TIdSipInboundSession read fSession write fSession;
  end;

  EIdSipBadSyntax = class(EIdException);

const
  BadAuthorizationTokens = 'Bad Authorization tokens';
  MissingContactHeader =   'Missing Contact Header';

procedure ApplyTo(List: TList;
                  Lock: TCriticalSection;
                  Proc: TIdSipProcedure); overload;
implementation

uses
  IdGlobal, IdHashMessageDigest, IdSimpleParser, IdSipConsts, IdRandom,
  IdSdp, IdStack, SysUtils, IdUDPServer;

const
  BusyHere        = 'Incoming call rejected - busy here';
  CallForwarded   = 'Incoming call forwarded';
  InviteTimeout   = 'Incoming call timed out';
  LocalCancel     = 'Local end cancelled call';
  LocalHangUp     = 'Local end hung up';
  RemoteHangUp    = 'Remote end hung up';

//******************************************************************************
//* Unit Private procedures and functions                                      *
//******************************************************************************

procedure CopyList(Source: TList;
                   Lock: TCriticalSection;
                   Copy: TList);
var
  I: Integer;
begin
  Copy.Clear;
  Lock.Acquire;
  try
    for I := 0 to Source.Count - 1 do
      Copy.Add(Source[I]);
  finally
    Lock.Release;
  end;
end;

//******************************************************************************
//* Unit Public procedures and functions                                       *
//******************************************************************************

procedure ApplyTo(List: TList;
                  Lock: TCriticalSection;
                  Proc: TIdSipProcedure);
var
  Copy: TList;
  I: Integer;
begin
  Copy := TList.Create;
  try
    CopyList(List, Lock, Copy);

    for I := 0 to Copy.Count - 1 do
      try
        Proc(Copy[I]);
      except
      end;
  finally
    Copy.Free;
  end;
end;

//******************************************************************************
//* TIdSipAbstractCore                                                         *
//******************************************************************************
//* TIdSipAbstractCore Public methods ******************************************

constructor TIdSipAbstractCore.Create;
begin
  inherited Create;

  Self.Observed := TIdObservable.Create;

  Self.HostName              := Self.DefaultHostName;
  Self.Realm                 := Self.HostName;
  Self.RequireAuthentication := false;
end;

destructor TIdSipAbstractCore.Destroy;
begin
  Self.Observed.Free;

  inherited Destroy;
end;

procedure TIdSipAbstractCore.AddObserver(const Listener: IIdObserver);
begin
  Self.Observed.AddObserver(Listener);
end;

function TIdSipAbstractCore.CreateResponse(Request: TIdSipRequest;
                                           ResponseCode: Cardinal): TIdSipResponse;
begin
  Result := TIdSipResponse.InResponseTo(Request,
                                        ResponseCode);

  Self.PrepareResponse(Result, Request);
end;

function TIdSipAbstractCore.NextCallID: String;
begin
  Result := GRandomNumber.NextHexString + '@' + Self.HostName;
end;

function TIdSipAbstractCore.NextTag: String;
begin
  Result := GRandomNumber.NextSipUserAgentTag;
end;

procedure TIdSipAbstractCore.RemoveObserver(const Listener: IIdObserver);
begin
  Self.Observed.RemoveObserver(Listener);
end;

procedure TIdSipAbstractCore.SendRequest(Request: TIdSipRequest);
begin
  Self.Dispatcher.SendRequest(Request);
end;

procedure TIdSipAbstractCore.SendResponse(Response: TIdSipResponse);
begin
  Self.Dispatcher.SendResponse(Response);
end;

//* TIdSipAbstractCore Protected methods ***************************************

procedure TIdSipAbstractCore.ActOnRequest(Request: TIdSipRequest;
                                          Receiver: TIdSipTransport);
begin
end;

procedure TIdSipAbstractCore.ActOnResponse(Response: TIdSipResponse;
                                           Receiver: TIdSipTransport);
begin
end;

function TIdSipAbstractCore.AuthenticationHeader: String;
begin
  Result := WWWAuthenticateHeader;
end;

function TIdSipAbstractCore.AuthenticationHeaderValue: String;
begin
  Result := 'realm="' + Self.Realm + '",algorith="MD5",qop="auth",nonce="f00f"';
end;

function TIdSipAbstractCore.AuthenticationStatusCode: Cardinal;
begin
  Result := SIPUnauthorized;
end;

function TIdSipAbstractCore.HasAuthorization(Request: TIdSipRequest): Boolean;
begin
  // Proxies and User Agent Servers use different headers to
  // challenge/authenticate.

  Result := Request.HasAuthorization;
end;

procedure TIdSipAbstractCore.NotifyOfChange;
begin
  Self.Observed.NotifyListenersOfChange(Self);
end;

procedure TIdSipAbstractCore.OnReceiveRequest(Request: TIdSipRequest;
                                              Receiver: TIdSipTransport);
begin
  // By default, do nothing. We don't know yet how Proxies behave.
end;

procedure TIdSipAbstractCore.OnReceiveResponse(Response: TIdSipResponse;
                                               Receiver: TIdSipTransport);
begin
  // By default, do nothing. We don't know yet how Proxies behave.
end;

procedure TIdSipAbstractCore.PrepareResponse(Response: TIdSipResponse;
                                             Request: TIdSipRequest);
begin
  if not Request.ToHeader.HasTag then
    Response.ToHeader.Tag := Self.NextTag;

  if (Self.UserAgentName <> '') then
    Response.AddHeader(ServerHeader).Value := Self.UserAgentName;
end;

procedure TIdSipAbstractCore.RejectBadRequest(Request: TIdSipRequest;
                                               const Reason: String);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPBadRequest);
  try
    Response.StatusText := Reason;

    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipAbstractCore.RejectRequest(Reaction: TIdSipUserAgentReaction;
                                           Request: TIdSipRequest);
begin
 case Reaction of
   uarUnauthorized:     Self.RejectRequestUnauthorized(Request);
   uarBadAuthorization: Self.RejectBadAuthorization(Request);
 end;
end;

procedure TIdSipAbstractCore.RejectRequestUnauthorized(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request,
                                  Self.AuthenticationStatusCode);
  try
    Response.AddHeader(Self.AuthenticationHeader).Value := Self.AuthenticationHeaderValue;

    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

function TIdSipAbstractCore.WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction;
begin
  Result := uarAccept;

  if Self.RequireAuthentication then begin
    try
      if not Self.HasAuthorization(Request)
        or (Assigned(Self.Authenticator) and Self.Authenticator.Authenticate(Request)) then
        Result := uarUnauthorized;
    except
      on EAuthenticate do
        Result := uarBadAuthorization;
    end;
  end;
end;

function  TIdSipAbstractCore.WillAcceptResponse(Response: TIdSipResponse): TIdSipUserAgentReaction;
begin
  // cf RFC 3261 section 8.1.3.3
  if (Response.Path.Count > 1) then
    Result := uarTooManyVias
  else
    Result := uarAccept;
end;

//* TIdSipAbstractCore Private methods *****************************************

function TIdSipAbstractCore.DefaultHostName: String;
begin
  Result := 'localhost';
end;

procedure TIdSipAbstractCore.OnReceiveUnhandledRequest(Request: TIdSipRequest;
                                                       Receiver: TIdSipTransport);
var
  Reaction: TIdSipUserAgentReaction;
begin
  Reaction := Self.WillAcceptRequest(Request);
  if (Reaction = uarAccept) then
    Self.ActOnRequest(Request, Receiver)
  else
    Self.RejectRequest(Reaction, Request);
end;

procedure TIdSipAbstractCore.OnReceiveUnhandledResponse(Response: TIdSipResponse;
                                                        Receiver: TIdSipTransport);
begin
  // We silently discard unacceptable responses.
  if (Self.WillAcceptResponse(Response) = uarAccept) then
    Self.ActOnResponse(Response, Receiver);
end;

procedure TIdSipAbstractCore.RejectBadAuthorization(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPBadRequest);
  try
    Response.StatusText := BadAuthorizationTokens;

    Self.Dispatcher.Send(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipAbstractCore.SetDispatcher(Value: TIdSipTransactionDispatcher);
begin
  fDispatcher := Value;

  fDispatcher.AddUnhandledMessageListener(Self);
end;

//******************************************************************************
//* TIdSipAbstractUserAgent                                                    *
//******************************************************************************
//* TIdSipAbstractUserAgent Public methods *************************************

constructor TIdSipAbstractUserAgent.Create;
begin
  inherited Create;

  Self.fAllowedContentTypeList := TStringList.Create;
  Self.fAllowedLanguageList    := TStringList.Create;
  Self.fAllowedMethodList      := TStringList.Create;
  Self.fAllowedSchemeList      := TStringList.Create;
end;

destructor TIdSipAbstractUserAgent.Destroy;
begin
  Self.AllowedSchemeList.Free;
  Self.AllowedMethodList.Free;
  Self.AllowedLanguageList.Free;
  Self.AllowedContentTypeList.Free;

  inherited Destroy;
end;

procedure TIdSipAbstractUserAgent.AddAllowedContentType(const MimeType: String);
begin
  if (Trim(MimeType) <> '') then begin
    if (Self.AllowedContentTypeList.IndexOf(MimeType) = -1) then
      Self.AllowedContentTypeList.Add(MimeType);
  end;
end;

procedure TIdSipAbstractUserAgent.AddAllowedLanguage(const LanguageID: String);
begin
  if (Trim(LanguageID) = '') then
    raise EIdSipBadSyntax.Create('Not a valid language identifier');

  if (Self.AllowedLanguageList.IndexOf(LanguageID) = -1) then
    Self.AllowedLanguageList.Add(LanguageID);
end;

procedure TIdSipAbstractUserAgent.AddAllowedMethod(const Method: String);
begin
  if not TIdSipParser.IsToken(Method) then
    raise EIdSipBadSyntax.Create('Not a token');

  if (Self.AllowedMethodList.IndexOf(Method) = -1) then
    Self.AllowedMethodList.Add(Method);
end;

procedure TIdSipAbstractUserAgent.AddAllowedScheme(const Scheme: String);
begin
  if not TIdSipParser.IsScheme(Scheme) then
    raise EIdSipBadSyntax.Create('Not a valid scheme');

  if (Self.AllowedSchemeList.IndexOf(Scheme) = -1) then
    Self.AllowedSchemeList.Add(Scheme);
end;

function TIdSipAbstractUserAgent.AllowedContentTypes: String;
begin
  Result := Self.ConvertToHeader(Self.AllowedContentTypeList);
end;

function TIdSipAbstractUserAgent.AllowedEncodings: String;
begin
  Result := '';
end;

function TIdSipAbstractUserAgent.AllowedExtensions: String;
begin
  Result := '';
end;

function TIdSipAbstractUserAgent.AllowedLanguages: String;
begin
  Result := Self.ConvertToHeader(Self.AllowedLanguageList);
end;

function TIdSipAbstractUserAgent.AllowedMethods: String;
begin
  Result := Self.ConvertToHeader(Self.AllowedMethodList);
end;

function TIdSipAbstractUserAgent.AllowedSchemes: String;
begin
  Result := Self.ConvertToHeader(Self.AllowedSchemeList);
end;

function TIdSipAbstractUserAgent.CreateRequest(Dest: TIdSipAddressHeader): TIdSipRequest;
begin
  Result := TIdSipRequest.Create;
  try
    Result.RequestUri     := Dest.Address;
    Result.From           := Self.From;
    Result.From.Tag       := Self.NextTag;
    Result.ToHeader.Value := Dest.FullValue;

    Result.CallID          := Self.NextCallID;
    Result.CSeq.SequenceNo := Self.NextInitialSequenceNo;

    Self.AddLocalHeaders(Result);
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipAbstractUserAgent.HasUnknownContentEncoding(Request: TIdSipRequest): Boolean;
begin
  Result := Request.HasHeader(ContentEncodingHeaderFull);
end;

function TIdSipAbstractUserAgent.HasUnknownContentLanguage(Request: TIdSipRequest): Boolean;
begin
  Result := Request.HasHeader(ContentLanguageHeader)
       and (Self.AllowedLanguageList.IndexOf(Request.FirstHeader(ContentLanguageHeader).Value) = -1);
end;

function TIdSipAbstractUserAgent.HasUnknownContentType(Request: TIdSipRequest): Boolean;
begin
  Result := Request.HasHeader(ContentTypeHeaderFull)
       and (Self.AllowedContentTypeList.IndexOf(Request.FirstHeader(ContentTypeHeaderFull).Value) = -1);
end;

function TIdSipAbstractUserAgent.IsExtensionAllowed(const Extension: String): Boolean;
begin
  Result := false;
end;

function TIdSipAbstractUserAgent.IsMethodAllowed(const Method: String): Boolean;
begin
  Result := Self.AllowedMethodList.IndexOf(Method) >= 0;
end;

function TIdSipAbstractUserAgent.IsSchemeAllowed(const Scheme: String): Boolean;
begin
  Result := Self.AllowedSchemeList.IndexOf(Scheme) >= 0;
end;

function TIdSipAbstractUserAgent.NextBranch: String;
begin
  Result := GRandomNumber.NextSipUserAgentBranch;
end;

function TIdSipAbstractUserAgent.NextInitialSequenceNo: Cardinal;
begin
  Result := GRandomNumber.NextCardinal($7FFFFFFF);
end;

procedure TIdSipAbstractUserAgent.RemoveAllowedMethod(const Method: String);
var
  Index: Integer;
begin
  Index := Self.AllowedMethodList.IndexOf(Method);

  if (Index <> -1) then
    Self.AllowedMethodList.Delete(Index);
end;

procedure TIdSipAbstractUserAgent.ReturnResponse(Request: TIdSipRequest;
                                                 Reason: Cardinal);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, Reason);
  try
    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

//* TIdSipAbstractUserAgent Protected methods **********************************

procedure TIdSipAbstractUserAgent.AddLocalHeaders(OutboundRequest: TIdSipRequest);
var
  Transport: String;
begin
  // The transport must be discovered using RFC 3263
  // TODO: Lies. Pure hack to get X-Lite talking

  if OutboundRequest.ToHeader.Address.HasParameter(TransportParam) then
    Transport := OutboundRequest.ToHeader.Address.Transport
  else
    Transport := TransportParamTCP;

//  Transport := TransportParamUDP;

  OutboundRequest.AddHeader(ViaHeaderFull).Value := SipVersion + '/' + Transport + ' ' + Self.HostName;

  OutboundRequest.LastHop.Branch := Self.NextBranch;

  if (Self.UserAgentName <> '') then
    OutboundRequest.AddHeader(UserAgentHeader).Value := Self.UserAgentName;
end;

procedure TIdSipAbstractUserAgent.RejectRequest(Reaction: TIdSipUserAgentReaction;
                                                Request: TIdSipRequest);
begin
  inherited RejectRequest(Reaction, Request);

  case Reaction of
    uarLoopDetected:
      Self.ReturnResponse(Request, SIPLoopDetected);
    uarUnsupportedContentEncoding:
      Self.RejectRequestUnknownContentEncoding(Request);
    uarUnsupportedContentLanguage:
      Self.RejectRequestUnknownContentLanguage(Request);
    uarUnsupportedContentType:
      Self.RejectRequestUnknownContentType(Request);
    uarUnsupportedExtension:
      Self.RejectRequestBadExtension(Request);
    uarUnsupportedMethod:
      Self.RejectRequestMethodNotAllowed(Request);
    uarUnsupportedScheme:
      Self.ReturnResponse(Request, SIPUnsupportedURIScheme);
    uarUnSupportedSipVersion:
      Self.RejectUnsupportedSipVersion(Request);
  end;
end;

procedure TIdSipAbstractUserAgent.RejectRequestBadExtension(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  // We simply reject ALL Requires
  Response := Self.CreateResponse(Request, SIPBadExtension);
  try
    Response.AddHeader(UnsupportedHeader).Value := Request.FirstHeader(RequireHeader).Value;

    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

function TIdSipAbstractUserAgent.WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction;
begin
  Result := inherited WillAcceptRequest(Request);

  // cf RFC 3261 section 8.2
  if (Result = uarAccept) then begin
    if (Request.SIPVersion <> SipVersion) then
      Result := uarUnsupportedSipVersion
    // inspect the method - 8.2.1
    else if not Request.IsAck and not Self.IsMethodAllowed(Request.Method) then
      Result := uarUnsupportedMethod
    // inspect the headers - 8.2.2
    // To & Request-URI - 8.2.2.1
    else if not Self.IsSchemeAllowed(Request.RequestUri.Scheme) then
      Result := uarUnsupportedScheme
    // Merged requests - 8.2.2.2
    else if not Request.ToHeader.HasTag and Self.Dispatcher.LoopDetected(Request) then
      Result := uarLoopDetected
    // Require - 8.2.2.3
    else if Request.HasHeader(RequireHeader) then
      Result := uarUnsupportedExtension
    // Content processing - 8.2.3
    else if Self.HasUnknownContentEncoding(Request) then
      Result := uarUnsupportedContentEncoding
    else if Self.HasUnknownContentLanguage(Request) then
      Result := uarUnsupportedContentLanguage
    else if Self.HasUnknownContentType(Request) then
      Result := uarUnsupportedContentType;
  end;
end;

//* TIdSipAbstractUserAgent Private methods ************************************

function TIdSipAbstractUserAgent.ConvertToHeader(ValueList: TStrings): String;
begin
  Result := StringReplace(ValueList.CommaText, ',', ', ', [rfReplaceAll]);
end;

function TIdSipAbstractUserAgent.GetFrom: TIdSipFromHeader;
begin
  if not Assigned(fFrom) then
    fFrom := TIdSipFromHeader.Create;

  Result := fFrom;
end;

procedure TIdSipAbstractUserAgent.RejectRequestMethodNotAllowed(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPMethodNotAllowed);
  try
    Response.StatusText := Response.StatusText + ' (' + Request.Method + ')';
    Response.AddHeader(AllowHeader).Value := Self.AllowedMethods;

    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipAbstractUserAgent.RejectRequestUnknownContentEncoding(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPUnsupportedMediaType);
  try
    Response.AddHeader(AcceptEncodingHeader).Value := '';

    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipAbstractUserAgent.RejectRequestUnknownContentLanguage(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPUnsupportedMediaType);
  try
    Response.AddHeader(AcceptLanguageHeader).Value := Self.AllowedLanguages;

    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipAbstractUserAgent.RejectRequestUnknownContentType(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPUnsupportedMediaType);
  try
    Response.AddHeader(AcceptHeader).Value := Self.AllowedContentTypes;

    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipAbstractUserAgent.RejectUnsupportedSipVersion(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPSIPVersionNotSupported);
  try
    Self.Dispatcher.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipAbstractUserAgent.SetFrom(Value: TIdSipFromHeader);
begin
  Self.From.Assign(Value);
end;

//******************************************************************************
//* TIdSipRegistrationInfo                                                     *
//******************************************************************************
//* TIdSipRegistrationInfo Public methods **************************************

constructor TIdSipRegistrationInfo.Create;
begin
  inherited Create;

  Self.fRegistrar := TIdSipUri.Create;
end;

destructor TIdSipRegistrationInfo.Destroy;
begin
  Self.Registrar.Free;

  inherited Destroy;
end;

//******************************************************************************
//* TIdSipUserAgentCore                                                        *
//******************************************************************************
//* TIdSipUserAgentCore Public methods *****************************************

constructor TIdSipUserAgentCore.Create;
begin
  inherited Create;

  Self.fProxy := TIdSipUri.Create('');

  Self.KnownRegistrars := TObjectList.Create(true);

  Self.ActionLock         := TCriticalSection.Create;
  Self.Actions            := TObjectList.Create;
  Self.UserAgentListeners := TIdNotificationList.Create;

  Self.fAllowedContentTypeList := TStringList.Create;
  Self.fAllowedLanguageList    := TStringList.Create;

  Self.AddAllowedContentType(SdpMimeType);
  Self.AddAllowedMethod(MethodBye);
  Self.AddAllowedMethod(MethodCancel);
  Self.AddAllowedMethod(MethodInvite);
  Self.AddAllowedMethod(MethodOptions);
  Self.AddAllowedScheme(SipScheme);

  Self.DoNotDisturb        := false;
  Self.DoNotDisturbMessage := RSSIPTemporarilyUnavailable;
  Self.From.Value          := Self.DefaultFrom;
  Self.HasProxy            := false;
  Self.HostName            := Self.DefaultHostName;
  Self.UserAgentName       := Self.DefaultUserAgent;
end;

destructor TIdSipUserAgentCore.Destroy;
begin
  Self.Contact.Free;
  Self.From.Free;
  Self.UserAgentListeners.Free;
  Self.Actions.Free;
  Self.ActionLock.Free;  
  Self.KnownRegistrars.Free;
  Self.Proxy.Free;

  inherited Destroy;
end;

procedure TIdSipUserAgentCore.AddUserAgentListener(const Listener: IIdSipUserAgentListener);
begin
  Self.UserAgentListeners.AddListener(Listener);
end;

function TIdSipUserAgentCore.Call(Dest: TIdSipAddressHeader;
                                  const InitialOffer: String;
                                  const MimeType: String): TIdSipOutboundSession;
begin
  Result := Self.AddOutboundSession;
  Result.Call(Dest, InitialOffer, MimeType);
end;

function TIdSipUserAgentCore.CreateAck(Dialog: TIdSipDialog): TIdSipRequest;
begin
  try
    Result := Dialog.CreateAck;
    Self.AddLocalHeaders(Result);
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipUserAgentCore.CreateBye(Dialog: TIdSipDialog): TIdSipRequest;
begin
  try
    Result := Self.CreateRequest(Dialog);
    Result.Method      := MethodBye;
    Result.CSeq.Method := Result.Method;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipUserAgentCore.CreateInvite(Dest: TIdSipAddressHeader;
                                          const Body: String;
                                          const MimeType: String): TIdSipRequest;
begin
  Result := Self.CreateRequest(Dest);
  try
    Self.TurnIntoInvite(Result, Body, MimeType);
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipUserAgentCore.CreateOptions(Dest: TIdSipAddressHeader): TIdSipRequest;
begin
  Result := Self.CreateRequest(Dest);
  try
    Result.Method := MethodOptions;
    Result.CSeq.Method := Result.Method;

    Result.AddHeader(AcceptHeader).Value := Self.AllowedContentTypes;
  except
    FreeAndNil(Result);
  end;
end;

function TIdSipUserAgentCore.CreateRegister(Registrar: TIdSipToHeader): TIdSipRequest;
begin
  Result := Self.CreateRequest(Registrar);
  try
    Self.AddKnownRegistrar(Registrar.Address,
                           Result.CallID,
                           Result.CSeq.SequenceNo);

    Result.Method := MethodRegister;
    Result.RequestUri.EraseUserInfo;

    Result.CSeq.Method     := MethodRegister;
    Result.CSeq.SequenceNo := Self.NextSequenceNoFor(Registrar.Address);

    Result.CallID := Self.CallIDFor(Registrar.Address);

    Result.ToHeader.Value := Self.Contact.Value;
    Result.From.Value     := Self.Contact.Value;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipUserAgentCore.CreateReInvite(Dialog: TIdSipDialog;
                                            const Body: String;
                                            const MimeType: String): TIdSipRequest;
begin
  Result := Self.CreateRequest(Dialog);
  try
    Self.TurnIntoInvite(Result, Body, MimeType);
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipUserAgentCore.CreateRequest(Dialog: TIdSipDialog): TIdSipRequest;
begin
  Result := Dialog.CreateRequest;
  try
    Self.AddLocalHeaders(Result);
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipUserAgentCore.CreateResponse(Request: TIdSipRequest;
                                            ResponseCode: Cardinal): TIdSipResponse;
begin
  Result := TIdSipResponse.InResponseTo(Request,
                                        ResponseCode,
                                        Self.Contact);

  Self.PrepareResponse(Result, Request);
end;

function TIdSipUserAgentCore.CurrentRegistrationWith(Registrar: TIdSipUri): TIdSipOutboundRegistration;
begin
  Result := Self.AddOutboundRegistration;

  Result.RegisterWith(Registrar, Self.Contact);
end;

procedure TIdSipUserAgentCore.TerminateAllCalls;
var
  CopyOfSessions: TObjectList;
  I:              Integer;
begin
  // We copy the sessions because when they terminate we lose our reference
  // to them and we remove them from Self.Actions
  Self.ActionLock.Acquire;
  try
    CopyOfSessions := TObjectList.Create(false);
    try
      for I := 0 to Self.Actions.Count - 1 do
        if Self.ActionAt(I).IsSession and not Self.ActionAt(I).IsTerminated then
          CopyOfSessions.Add(Self.ActionAt(I));

      for I := 0 to CopyOfSessions.Count - 1 do
        (CopyOfSessions[I] as TIdSipAction).Terminate;
    finally
      CopyOfSessions.Free;
    end;
  finally
    Self.ActionLock.Release;
  end;
end;

function TIdSipUserAgentCore.OptionsCount: Integer;
var
  I: Integer;
begin
  // Return the number of ongoing options queries
  Self.ActionLock.Acquire;
  try
    Result := 0;

    for I := 0 to Self.Actions.Count - 1 do
      if Self.ActionAt(I).IsOptions
        and not Self.ActionAt(I).IsTerminated then Inc(Result);
  finally
    Self.ActionLock.Release;
  end;
end;

function TIdSipUserAgentCore.QueryOptions(Server: TIdSipAddressHeader): TIdSipOutboundOptions;
begin
  Result := Self.AddOutboundOptions;

  Result.QueryOptions(Server);
end;

function TIdSipUserAgentCore.RegisterWith(Registrar: TIdSipUri): TIdSipOutboundRegistration;
begin
  Result := Self.AddOutboundRegistration;

  Result.RegisterWith(Registrar, Self.Contact);
end;

function TIdSipUserAgentCore.RegistrationCount: Integer;
var
  I: Integer;
begin
  // Return the number of ongoing registration attempts
  Self.ActionLock.Acquire;
  try
    Result := 0;

    for I := 0 to Self.Actions.Count - 1 do
      if Self.ActionAt(I).IsRegistration
        and not Self.ActionAt(I).IsTerminated then Inc(Result);
  finally
    Self.ActionLock.Release;
  end;
end;

procedure TIdSipUserAgentCore.RemoveAction(Action: TIdSipAction);
begin
//  if not Action.IsTerminated then
//    Action.Terminate;

  Self.ActionLock.Acquire;
  try
    Self.Actions.Remove(Action);
  finally
    Self.ActionLock.Release;
  end;
  Self.NotifyOfChange;
end;

procedure TIdSipUserAgentCore.RemoveUserAgentListener(const Listener: IIdSipUserAgentListener);
begin
  Self.UserAgentListeners.RemoveListener(Listener);
end;

function TIdSipUserAgentCore.SessionCount: Integer;
var
  I: Integer;
begin
  // Return the number of ongoing Sessions
  Self.ActionLock.Acquire;
  try
    Result := 0;

    for I := 0 to Self.Actions.Count - 1 do
      if Self.ActionAt(I).IsSession
        and not Self.ActionAt(I).IsTerminated then
        Inc(Result);
  finally
    Self.ActionLock.Release;
  end;
end;

function TIdSipUserAgentCore.UnregisterFrom(Registrar: TIdSipUri): TIdSipOutboundRegistration;
begin
  Result := Self.AddOutboundRegistration;

  Result.Unregister(Registrar);
end;

function TIdSipUserAgentCore.Username: String;
begin
  Result := Self.From.Address.Username;
end;

//* TIdSipUserAgentCore Protected methods **************************************

procedure TIdSipUserAgentCore.ActOnRequest(Request: TIdSipRequest;
                                           Receiver: TIdSipTransport);
var
  Action:             TIdSipAction;
  ExpectedStatusCode: Cardinal;
begin
  inherited ActOnRequest(Request, Receiver);

  // Processing the request - 8.2.5
  Action := Self.FindAction(Request);

  if Assigned(Action) then
    Action.ReceiveRequest(Request)
  else begin
    if Request.IsBye then
      Self.ReturnResponse(Request,
                          SIPCallLegOrTransactionDoesNotExist)
    else if Request.IsInvite then begin
      ExpectedStatusCode := Self.ResponseForInvite;
      if (ExpectedStatusCode <> SIPOK) then
        Self.ReturnResponse(Request, ExpectedStatusCode)
      else
        Self.AddInboundSession(Request, Receiver.IsSecure)
    end
    else if Request.IsRegister then
      Self.AddInboundRegistration(Request).ReceiveRequest(Request)
    else if Request.IsOptions then
      Self.AddInboundOptions(Request).ReceiveRequest(Request);
  end;

  // TIdSipSession generates the response - 8.2.6
end;

procedure TIdSipUserAgentCore.ActOnResponse(Response: TIdSipResponse;
                                            Receiver: TIdSipTransport);
var
  Action: TIdSipAction;
begin
  inherited ActOnResponse(Response, Receiver);

  // User Agents drop unmatched responses on the floor.
  // Except for 2xx's on a client INVITE. And these no longer belong to
  // a transaction, since the receipt of a 200 terminates a client INVITE
  // immediately.
  if Response.IsOK then begin
    Action := Self.FindAction(Response);

    if not Assigned(Action) then
      Action := Self.ForkCall(Response);

    if Assigned(Action) then
      Action.ReceiveResponse(Response, Receiver.IsSecure);
  end
  else
    Self.NotifyOfDroppedResponse(Response, Receiver);
end;

procedure TIdSipUserAgentCore.AddLocalHeaders(OutboundRequest: TIdSipRequest);
begin
  inherited AddLocalHeaders(OutboundRequest);

  OutboundRequest.AddHeader(Self.Contact);

  if Self.HasProxy then
    OutboundRequest.Route.AddRoute(Self.Proxy);

  if OutboundRequest.HasSipsUri then
    OutboundRequest.FirstContact.Address.Scheme := SipsScheme;
end;

procedure TIdSipUserAgentCore.OnReceiveRequest(Request: TIdSipRequest;
                                               Receiver: TIdSipTransport);
var
  Action: TIdSipAction;
begin
  Action := Self.FindAction(Request);

  if Assigned(Action) then
    Action.ReceiveRequest(Request);
end;

procedure TIdSipUserAgentCore.OnReceiveResponse(Response: TIdSipResponse;
                                                Receiver: TIdSipTransport);
var
  Action:               TIdSipAction;
  UsingSecureTransport: Boolean;
begin
  UsingSecureTransport := Receiver.IsSecure;

  Action := Self.FindAction(Response);

  if Assigned(Action) then
    Action.ReceiveResponse(Response, UsingSecureTransport)
  else
    Self.NotifyOfDroppedResponse(Response, Receiver);
end;

procedure TIdSipUserAgentCore.RejectRequest(Reaction: TIdSipUserAgentReaction;
                                            Request: TIdSipRequest);
begin
  inherited RejectRequest(Reaction, Request);

  case Reaction of
    uarMissingContact:
      Self.RejectBadRequest(Request, MissingContactHeader);
  end;
end;

function TIdSipUserAgentCore.WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction;
begin
  Result := inherited WillAcceptRequest(Request);

  if (Result = uarAccept) then begin
    // Section 8.1.1.8 says that a request that can start a dialog (like an
    // INVITE), MUST contain a Contact.
    if Request.IsInvite and not Request.HasHeader(ContactHeaderFull) then
      Result := uarMissingContact;
  end;
end;

//* TIdSipUserAgentCore Private methods ****************************************

function TIdSipUserAgentCore.ActionAt(Index: Integer): TIdSipAction;
begin
  // Precondition: you've invoked Self.ActionLock.Acquire
  Result := Self.Actions[Index] as TIdSipAction;
end;

function TIdSipUserAgentCore.AddFork(RootSession: TIdSipOutboundSession;
                                     Response: TIdSipResponse): TIdSipOutboundSession;
begin
  // RFC 3261, section 13.2.2.4

  Self.ActionLock.Acquire;
  try
    Result := RootSession.Fork(Response);
    Self.Actions.Add(Result);
  finally
    Self.ActionLock.Release;
  end;

  Self.NotifyOfChange;
end;

function TIdSipUserAgentCore.AddInboundOptions(Options: TIdSipRequest): TIdSipInboundOptions;
begin
  Result := TIdSipInboundOptions.Create(Self, Options);
  try
    Self.ActionLock.Acquire;
    try
      Self.Actions.Add(Result);
    finally
      Self.ActionLock.Release;
    end;

  except
    FreeAndNil(Result);
  end;
end;

function TIdSipUserAgentCore.AddInboundRegistration(Reg: TIdSipRequest): TIdSipInboundRegistration;
begin
  Result := TIdSipInboundRegistration.Create(Self, Reg);
  try
    Self.ActionLock.Acquire;
    try
      Self.Actions.Add(Result);
    finally
      Self.ActionLock.Release;
    end;

  except
    FreeAndNil(Result);
  end;
end;

function TIdSipUserAgentCore.AddInboundSession(Invite: TIdSipRequest;
                                               UsingSecureTransport: Boolean): TIdSipInboundSession;
begin
  Result := TIdSipInboundSession.Create(Self, Invite, UsingSecureTransport);
  try
    Self.ActionLock.Acquire;
    try
      Self.Actions.Add(Result);
    finally
      Self.ActionLock.Release;
    end;

    Self.NotifyOfInboundCall(Result);
    Self.NotifyOfChange;

    if Invite.HasHeader(ExpiresHeader) then begin
      TIdSipSingleShotTimer.Create(Self.OnInboundSessionExpire,
                                   Invite.FirstExpires.NumericValue,
                                   Invite.Copy);
    end;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

procedure TIdSipUserAgentCore.AddKnownRegistrar(Registrar: TIdSipUri;
                                                const CallID: String;
                                                SequenceNo: Cardinal);
var
  NewReg: TIdSipRegistrationInfo;
begin
  if not Self.KnowsRegistrar(Registrar) then begin
    NewReg := TIdSipRegistrationInfo.Create;
    Self.KnownRegistrars.Add(NewReg);

    NewReg.CallID        := CallID;
    NewReg.Registrar.Uri := Registrar.Uri;
    NewReg.SequenceNo    := SequenceNo;
  end;
end;

function TIdSipUserAgentCore.AddOutboundOptions: TIdSipOutboundOptions;
begin
  Result := TIdSipOutboundOptions.Create(Self);
  try
    Self.ActionLock.Acquire;
    try
      Self.Actions.Add(Result);
    finally
      Self.ActionLock.Release;
    end;
    Self.NotifyOfChange;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipUserAgentCore.AddOutboundSession: TIdSipOutboundSession;
begin
  Result := TIdSipOutboundSession.Create(Self);
  try
    Self.ActionLock.Acquire;
    try
      Self.Actions.Add(Result);
    finally
      Self.ActionLock.Release;
    end;

    Self.NotifyOfChange;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipUserAgentCore.AddOutboundRegistration: TIdSipOutboundRegistration;
begin
  Result := TIdSipOutboundRegistration.Create(Self);
  try
    Self.ActionLock.Acquire;
    try
      Self.Actions.Add(Result);
    finally
      Self.ActionLock.Release;
    end;
    Self.NotifyOfChange;
  except
    FreeAndNil(Result);

    raise;
  end;
end;


function TIdSipUserAgentCore.CallIDFor(Registrar: TIdSipUri): String;
begin
  Assert(Self.KnowsRegistrar(Registrar), 'A registrar wasn''t added');
  Result := Self.RegistrarAt(Self.IndexOfRegistrar(Registrar)).CallID
end;

function TIdSipUserAgentCore.DefaultFrom: String;
begin
  Result := 'unknown <sip:unknown@' + Self.HostName + '>';
end;

function TIdSipUserAgentCore.DefaultUserAgent: String;
begin
  Result := 'Indy SIP/2.0 Server v0.1';
end;

function TIdSipUserAgentCore.FindAction(Msg: TIdSipMessage): TIdSipAction;
var
  I:      Integer;
  Action: TIdSipAction;
begin
  Result := nil;
  Self.ActionLock.Acquire;
  try
    I := 0;
    while (I < Self.Actions.Count) and not Assigned(Result) do begin
      Action := Self.Actions[I] as TIdSipAction;
      if Action.Match(Msg) and not Action.IsTerminated then
        Result := Action
      else
        Inc(I);
    end;
  finally
    Self.ActionLock.Release;
  end;
end;

function TIdSipUserAgentCore.ForkCall(Response: TIdSipResponse): TIdSipOutboundSession;
var
  Root:    TIdSipOutboundSession;
  I:       Integer;
  Session: TIdSipOutboundSession;
begin
  // We received a second (or third, or...) 2xx in response to an INVITE.
  // We create a new outbound session. This means we need to find the
  // INVITE.

  Result := nil;
  Root   := nil;
  Self.ActionLock.Acquire;
  try
    I := 0;
    while (I < Self.Actions.Count) and not Assigned(Root) do begin
      if (Self.Actions[I] is TIdSipSession) and
        (Self.Actions[I] as TIdSipSession).IsInboundCall then Inc(I)
      else begin
        Session := Self.Actions[I] as TIdSipOutboundSession;
        if Session.CanForkOn(Response) then
          Root := Session
        else
          Inc(I);
      end;
    end;

    if Assigned(Root) then begin
      Result := Self.AddFork(Root, Response);
    end;

  finally
    Self.ActionLock.Release;
  end;
end;

function TIdSipUserAgentCore.GetContact: TIdSipContactHeader;
begin
  if not Assigned(fContact) then
    fContact := TIdSipContactHeader.Create;

  Result := fContact;
end;

function TIdSipUserAgentCore.GetDefaultRegistrationExpiryTime: Cardinal;
begin
  Result := Self.BindingDB.DefaultExpiryTime;
end;

function TIdSipUserAgentCore.IndexOfRegistrar(Registrar: TIdSipUri): Integer;
begin
  // Precondition: something's acquired the RegistrationLock
  Result := 0;
  while (Result < Self.KnownRegistrars.Count) do
    if Self.RegistrarAt(Result).Registrar.Equals(Registrar) then
      Break
    else
      Inc(Result);

  if (Result >= Self.KnownRegistrars.Count) then
    Result := -1;
end;

function TIdSipUserAgentCore.KnowsRegistrar(Registrar: TIdSipUri): Boolean;
begin
  // Precondition: something's acquired the RegistrationLock
  Result := Self.IndexOfRegistrar(Registrar) <> -1;
end;

function TIdSipUserAgentCore.NextSequenceNoFor(Registrar: TIdSipUri): Cardinal;
var
  RegInfo: TIdSipRegistrationInfo;
begin
  Assert(Self.KnowsRegistrar(Registrar), 'A registrar wasn''t added');

  RegInfo := Self.RegistrarAt(Self.IndexOfRegistrar(Registrar));
  Result := RegInfo.SequenceNo;
  RegInfo.SequenceNo := Result + 1;
end;

procedure TIdSipUserAgentCore.NotifyOfInboundCall(Session: TIdSipInboundSession);
var
  Notification: TIdSipUserAgentInboundCallMethod;
begin
  Notification := TIdSipUserAgentInboundCallMethod.Create;
  try
    Notification.Session := Session;

    Self.UserAgentListeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipUserAgentCore.NotifyOfDroppedResponse(Response: TIdSipResponse;
                                                      Receiver: TIdSipTransport);
var
  Notification: TIdSipUserAgentDroppedUnmatchedResponseMethod;
begin
  Notification := TIdSipUserAgentDroppedUnmatchedResponseMethod.Create;
  try
    Notification.Receiver := Receiver;
    Notification.Response := Response;

    Self.UserAgentListeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipUserAgentCore.OnInboundSessionExpire(Sender: TObject);
var
  Session: TIdSipAction;
begin
  Self.ActionLock.Acquire;
  try
    Session := Self.FindAction((Sender as TIdSipSingleShotTimer).Data as TIdSipRequest);

    if Assigned(Session) then
      (Session as TIdSipInboundSession).TimeOut;
  finally
    Self.ActionLock.Release;
  end;

  (Sender as TIdSipSingleShotTimer).Data.Free;
end;

function TIdSipUserAgentCore.RegistrarAt(Index: Integer): TIdSipRegistrationInfo;
begin
  Result := Self.KnownRegistrars[Index] as TIdSipRegistrationInfo;
end;

function TIdSipUserAgentCore.ResponseForInvite: Cardinal;
begin
  // If we receive an INVITE (or an OPTIONS), what response code
  // would we return? If we don't wish to be disturbed, we return
  // SIPTemporarilyUnavailable; if we have no available lines, we
  // return SIPBusyHere, etc.

  if Self.DoNotDisturb then
    Result := SIPTemporarilyUnavailable
  else
    Result := SIPOK;
end;

procedure TIdSipUserAgentCore.SetContact(Value: TIdSipContactHeader);
begin
  Assert(not Value.IsWildCard,
         'You may not use a wildcard Contact header for a User Agent''s '
       + 'Contact');

  Self.Contact.Assign(Value);
end;

procedure TIdSipUserAgentCore.SetDefaultRegistrationExpiryTime(Value: Cardinal);
begin
  Self.BindingDB.DefaultExpiryTime := Value;
end;

procedure TIdSipUserAgentCore.SetProxy(Value: TIdSipUri);
begin
  Self.Proxy.Uri := Value.Uri;
end;

procedure TIdSipUserAgentCore.TurnIntoInvite(OutboundRequest: TIdSipRequest;
                                             const Offer: String;
                                             const OfferMimeType: String);
begin
  OutboundRequest.Method      := MethodInvite;
  OutboundRequest.CSeq.Method := MethodInvite;

  OutboundRequest.Body := Offer;
  OutboundRequest.ContentLength := Length(Offer);

  if (OutboundRequest.ContentLength > 0) then begin
    OutboundRequest.ContentDisposition.Value := DispositionSession;
    OutboundRequest.ContentType              := OfferMimeType;
  end;

  OutboundRequest.AddHeader(AllowHeader).Value := Self.AllowedMethods;
  // TODO: We need to add a proper extension support thing, as well as do a
  // proper payload processor capable of handling multiple content types
  OutboundRequest.AddHeader(AcceptHeader).Value := Self.AllowedContentTypes;
  OutboundRequest.AddHeader(SupportedHeaderFull).Value := Self.AllowedExtensions;
end;

//******************************************************************************
//* TIdSipAction                                                               *
//******************************************************************************
//* TIdSipAction Public methods ************************************************

constructor TIdSipAction.Create(UA: TIdSipUserAgentCore);
begin
  inherited Create;

  Self.UA := UA;

  Self.fCurrentRequest := TIdSipRequest.Create;
  Self.Listeners       := TIdNotificationList.Create;
  Self.NonceCount      := 0;
end;

destructor TIdSipAction.Destroy;
begin
  Self.Listeners.Free;
  Self.CurrentRequest.Free;

  inherited Destroy;
end;

function TIdSipAction.IsOptions: Boolean;
begin
  Result := false;
end;

function TIdSipAction.IsRegistration: Boolean;
begin
  Result := false;
end;

function TIdSipAction.IsSession: Boolean;
begin
  Result := false;
end;

function TIdSipAction.Match(Msg: TIdSipMessage): Boolean;
begin
  Result := Self.CurrentRequest.Match(Msg);
end;

procedure TIdSipAction.ReceiveRequest(Request: TIdSipRequest);
begin
end;

procedure TIdSipAction.ReceiveResponse(Response: TIdSipResponse;
                                       UsingSecureTransport: Boolean);
var
  Succeeded: Boolean;
begin
  // Each of the ReceiveXXXResponse functions returns true if we succeeded
  // in our Action, or we could re-issue the request. They only return
  // false when the action failed irrecoverably.

  case Response.StatusCode div 100 of
    SIPProvisionalResponseClass:
      Succeeded := Self.ReceiveProvisionalResponse(Response,
                                                   UsingSecureTransport);
    SIPOKResponseClass:
      Succeeded := Self.ReceiveOKResponse(Response,
                                          UsingSecureTransport);
    SIPRedirectionResponseClass:
      Succeeded := Self.ReceiveRedirectionResponse(Response,
                                                   UsingSecureTransport);
    SIPFailureResponseClass:
      Succeeded := Self.ReceiveFailureResponse(Response);
    SIPServerFailureResponseClass:
      Succeeded := Self.ReceiveServerFailureResponse(Response);
    SIPGlobalFailureResponseClass:
      Succeeded := Self.ReceiveGlobalFailureResponse(Response);
  else
    // This should never happen - response status codes lie in the range
    // 100 <= S < 700, so we just reject these obviously malformed responses
    // by silently discarding them.
    Succeeded := false;
  end;

  if Succeeded then
    Self.ActionSucceeded(Response)
  else
    Self.NotifyOfFailure(Response);
end;

procedure TIdSipAction.Terminate;
begin
  Self.MarkAsTerminated;
end;

//* TIdSipAction Protected methods *********************************************

procedure TIdSipAction.ActionSucceeded(Response: TIdSipResponse);
begin
  // By default do nothing.
end;

procedure TIdSipAction.MarkAsTerminated;
begin
  Self.fIsTerminated := true;
end;

function TIdSipAction.NotifyOfAuthenticationChallenge(Response: TIdSipResponse): String;
var
  Notification: TIdSipActionListenerAuthenticationChallengeMethod;
begin
  // We present the authentication challenge to all listeners but only accept
  // the first listener's password. The responsibility of listener order rests
  // firmly on your own shoulders.

  Notification := TIdSipActionListenerAuthenticationChallengeMethod.Create;
  try
    Notification.Action   := Self;
    Notification.Response := Response;

    Self.Listeners.Notify(Notification);

    Result := Notification.FirstPassword;
  finally
    Notification.Free;
  end;
end;

procedure TIdSipAction.NotifyOfFailure(Response: TIdSipResponse);
begin
end;

function TIdSipAction.ReceiveFailureResponse(Response: TIdSipResponse): Boolean;
begin
  // We received a 401 Unauthorized or 407 Proxy Authentication Required response
  // so we need to re-issue the INVITE with the necessary authorization details.
  case Response.StatusCode of
    SIPUnauthorized: begin
      Self.AuthorizeAgainstUser(Response);
      Result := true;
    end;
    SIPProxyAuthenticationRequired: begin
      Self.AuthorizeAgainstProxy(Response);
      Result := true;
    end;
  else
    Result := false;
  end;
end;

function TIdSipAction.ReceiveGlobalFailureResponse(Response: TIdSipResponse): Boolean;
begin
  Result := false;
end;

function TIdSipAction.ReceiveOKResponse(Response: TIdSipResponse;
                                        UsingSecureTransport: Boolean): Boolean;
begin
  Result := true;
end;

function TIdSipAction.ReceiveProvisionalResponse(Response: TIdSipResponse;
                                                 UsingSecureTransport: Boolean): Boolean;
begin
  Result := false;
end;

function TIdSipAction.ReceiveRedirectionResponse(Response: TIdSipResponse;
                                                 UsingSecureTransport: Boolean): Boolean;
var
  ReInvite: TIdSipRequest;
begin
  Result := false;
  if Response.HasHeader(ContactHeaderFull) then begin
    ReInvite := TIdSipRequest.Create;
    try
      ReInvite.Assign(Self.CurrentRequest);
      ReInvite.LastHop.Branch := Self.UA.NextBranch;
      ReInvite.FirstContact.Assign(Response.FirstContact);

      Self.SendRequest(ReInvite);
    finally
      ReInvite.Free;
    end;
    Result := true;
  end;
end;

function TIdSipAction.ReceiveServerFailureResponse(Response: TIdSipResponse): Boolean;
begin
  Result := false;
end;

procedure TIdSipAction.SendRequest(Request: TIdSipRequest);
begin
  if (Self.NonceCount = 0) then
    Inc(Self.NonceCount);

  Self.UA.SendRequest(Request);
end;

procedure TIdSipAction.SendResponse(Response: TIdSipResponse);
begin
  Self.UA.SendResponse(Response);
end;

//* TIdSipAction Private methods ***********************************************

function TIdSipAction.AddAuthorizationHeader(ReAttempt: TIdSipRequest;
                                             Challenge: TIdSipResponse): TIdSipAuthorizationHeader;
begin
  if Challenge.HasProxyAuthenticate then
    Result := ReAttempt.AddHeader(ProxyAuthorizationHeader) as TIdSipAuthorizationHeader
  else if Challenge.HasWWWAuthenticate then
    Result := ReAttempt.AddHeader(AuthorizationHeader) as TIdSipAuthorizationHeader
  else
    Result := nil;
end;

function TIdSipAction.AuthenticateHeader(Challenge: TIdSipResponse): TIdSipAuthenticateHeader;
begin
  if Challenge.HasProxyAuthenticate then
    Result := Challenge.FirstProxyAuthenticate
  else if Challenge.HasWWWAuthenticate then
    Result := Challenge.FirstWWWAuthenticate
  else
    Result := nil;
end;

procedure TIdSipAction.Authorize(Challenge: TIdSipResponse; AgainstProxy: Boolean);
var
  A1:              String;
  A2:              String;
  AuthHeader:      TIdSipAuthorizationHeader;
  ChallengeHeader: TIdSipHttpAuthHeader;
  Password:        String;
  ReAttempt:       TIdSipRequest;
begin
  Inc(Self.NonceCount);
  Password := Self.NotifyOfAuthenticationChallenge(Challenge);

  ReAttempt := Self.CreateNewAttempt(Challenge);
  try
    ReAttempt.CSeq.SequenceNo := Self.CurrentRequest.CSeq.SequenceNo + 1;

    AuthHeader      := Self.AddAuthorizationHeader(ReAttempt, Challenge);
    ChallengeHeader := Self.AuthenticateHeader(Challenge);

    AuthHeader.DigestUri := ReAttempt.RequestUri.AsString;
    AuthHeader.Nonce     := ChallengeHeader.Nonce;
    AuthHeader.Opaque    := ChallengeHeader.Opaque;
    AuthHeader.Realm     := ChallengeHeader.Realm;
    AuthHeader.Username  := Self.Username;

    if   (ChallengeHeader.Algorithm = MD5Name)
      or (ChallengeHeader.Algorithm = '') then
      A1 := AuthHeader.Username + ':' + AuthHeader.Realm + ':' + Password
    else
      A1 := 'completely wrong';

    if (ChallengeHeader.Qop <> '') then begin
      // TODO: Put a real cnonce here
      AuthHeader.CNonce := 'f00f00';
      AuthHeader.NonceCount := Self.NonceCount;

      A2 := ReAttempt.Method + ':'
          + AuthHeader.DigestUri + ':'
          + MD5(ReAttempt.Body);

      AuthHeader.Response := KD(MD5(A1),
                                AuthHeader.Nonce + ':'
                              + AuthHeader.NC + ':'
                              + AuthHeader.CNonce + ':'
                              + AuthHeader.Qop + ':'
                              + MD5(A2),
                                MD5);
    end
    else begin
      A2 := ReAttempt.Method + ':' + AuthHeader.DigestUri;

      AuthHeader.Response := KD(MD5(A1),
                                ChallengeHeader.Nonce + ':' + MD5(A2),
                                MD5);
    end;

    Self.CurrentRequest.Assign(ReAttempt);
    Self.SendRequest(ReAttempt);
  finally
    ReAttempt.Free;
  end;
end;

procedure TIdSipAction.AuthorizeAgainstProxy(Challenge: TIdSipResponse);
begin
  Self.Authorize(Challenge, true);
end;

procedure TIdSipAction.AuthorizeAgainstUser(Challenge: TIdSipResponse);
begin
  Self.Authorize(Challenge, false);
end;

function TIdSipAction.GetUsername: String;
begin
  Result := Self.UA.Username;
end;

procedure TIdSipAction.SetUsername(const Value: String);
begin
  Self.UA.From.DisplayName := Value;
end;

//******************************************************************************
//* TIdSipActionListenerAuthenticationChallengeMethod                          *
//******************************************************************************
//* TIdSipActionListenerAuthenticationChallengeMethod Public methods ***********

procedure TIdSipActionListenerAuthenticationChallengeMethod.Run(const Subject: IInterface);
var
  DiscardedPassword: String;
  Listener:          IIdSipActionListener;
begin
  Listener := Subject as IIdSipActionListener;
  
  if (Self.FirstPassword = '') then
    Listener.OnAuthenticationChallenge(Self.Action,
                                       Self.Response,
                                       Self.fFirstPassword)
  else
    Listener.OnAuthenticationChallenge(Self.Action,
                                       Self.Response,
                                       DiscardedPassword)
end;

//******************************************************************************
//* TIdSipSessionTimer                                                         *
//******************************************************************************
//* TIdSipSessionTimer Public methods ******************************************

constructor TIdSipSessionTimer.Create(Session: TIdSipInboundSession;
                                      T1: Cardinal;
                                      T2: Cardinal);
begin
  inherited Create;

  Self.Lock := TCriticalSection.Create;

  Self.Session := Session;
  Self.T1      := T1;
  Self.T2      := T2;

  Self.Timer := TIdSipTimer.Create;
  Self.Timer.Interval := Self.T1;
  Self.Timer.OnTimer  := Self.OnTimer;
end;

destructor TIdSipSessionTimer.Destroy;
begin
  Self.Timer.TerminateAndWaitFor;
  Self.Timer.Free;

  Self.Lock.Free;

  inherited Destroy;
end;

procedure TIdSipSessionTimer.Fire;
begin
  Self.Lock.Acquire;
  try
    Self.Timer.Interval := Min(2*Self.Timer.Interval, Self.T2);
  finally
    Self.Lock.Release;
  end;

  Self.Session.ResendLastResponse;
end;

procedure TIdSipSessionTimer.Start;
begin
  Self.Timer.Start;
end;

procedure TIdSipSessionTimer.Stop;
begin
  Self.Timer.Stop;
end;

function TIdSipSessionTimer.Interval: Cardinal;
begin
  Self.Lock.Acquire;
  try
    Result := Self.Timer.Interval;
  finally
    Self.Lock.Release;
  end;
end;

//* TIdSipSessionTimer Private methods *****************************************

procedure TIdSipSessionTimer.OnTimer(Sender: TObject);
begin
  Self.Fire;
end;

//******************************************************************************
//* TIdSipUserAgentFailMethod                                                  *
//******************************************************************************
//* TIdSipUserAgentFailMethod Public methods ***********************************

procedure TIdSipEndedSessionMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSessionListener).OnEndedSession(Self.Session,
                                                    Self.Reason);
end;

//******************************************************************************
//* TIdSipEstablishedSessionMethod                                             *
//******************************************************************************
//* TIdSipEstablishedSessionMethod Public methods ******************************

procedure TIdSipEstablishedSessionMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSessionListener).OnEstablishedSession(Self.Session);
end;

//******************************************************************************
//* TIdSipModifiedSessionMethod                                                *
//******************************************************************************
//* TIdSipModifiedSessionMethod Public methods *********************************

procedure TIdSipModifiedSessionMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSessionListener).OnModifiedSession(Self.Session,
                                                       Self.Request);
end;

//******************************************************************************
//* TIdSipSession                                                              *
//******************************************************************************
//* TIdSipSession Public methods ***********************************************

class function TIdSipSession.Method: String;
begin
  Result := MethodInvite;
end;

constructor TIdSipSession.Create(UA: TIdSipUserAgentCore);
begin
  inherited Create(UA);

  Self.DialogLock := TCriticalSection.Create;

  Self.fIsTerminated := false;
  Self.fReceivedAck  := false;

  Self.OpenTransactionLock := TCriticalSection.Create;
  Self.OpenTransactions    := TObjectList.Create(true);

  Self.FullyEstablished := false;
end;

destructor TIdSipSession.Destroy;
begin
  Self.OpenTransactions.Free;
  Self.OpenTransactionLock.Free;

  Self.DialogLock.Free;

  inherited Destroy;
end;

procedure TIdSipSession.AddSessionListener(const Listener: IIdSipSessionListener);
begin
  Self.Listeners.AddListener(Listener);
end;

function TIdSipSession.IsEarly: Boolean;
begin
  // This relies on short-circuited boolean expression evaluation
  Result := not Self.DialogEstablished or Self.Dialog.IsEarly;
end;

function TIdSipSession.DialogEstablished: Boolean;
begin
  Self.DialogLock.Acquire;
  try
    Result := Assigned(Self.fDialog);
  finally
    Self.DialogLock.Release;
  end;
end;

function TIdSipSession.IsOutboundCall: Boolean;
begin
  Result := not Self.IsInboundCall;
end;

function TIdSipSession.IsSession: Boolean;
begin
  Result := true;
end;

function TIdSipSession.Match(Msg: TIdSipMessage): Boolean;
var
  DialogID: TIdSipDialogID;
begin
  DialogID := Self.CreateDialogIDFrom(Msg);
  try
   if Self.DialogEstablished then
     Result := Self.Dialog.ID.Equals(DialogID)
   else
     Result := Self.CurrentRequest.Match(Msg);
  finally
    DialogID.Free;
  end;
end;

procedure TIdSipSession.Modify(const Offer, ContentType: String);
begin
end;

function TIdSipSession.PendingTransactionCount: Integer;
begin
  Self.OpenTransactionLock.Acquire;
  try
    Result := Self.OpenTransactions.Count;
  finally
    Self.OpenTransactionLock.Release;
  end;
end;

procedure TIdSipSession.ReceiveRequest(Request: TIdSipRequest);
begin
  if Self.IsTerminated then begin
    Self.RejectRequest(Request);
    Exit;
  end;

  if Request.IsBye then begin
    Self.ProcessBye(Request);
  end
  else if Request.IsInvite then begin
    if Self.Dialog.IsOutOfOrder(Request) then begin
      Self.RejectOutOfOrderRequest(Request);
      Exit;
    end;

//    if Request.Disposition.IsSession then
//      Self.PayloadProcessor.RemoteSessionDescription := Request.Body;

    Self.AddOpenTransaction(Request);
    Self.NotifyOfModifiedSession(Request);
  end;
end;

procedure TIdSipSession.RemoveSessionListener(const Listener: IIdSipSessionListener);
begin
  Self.Listeners.RemoveListener(Listener);
end;

//* TIdSipSession Protected methods ********************************************

procedure TIdSipSession.ActionSucceeded(Response: TIdSipResponse);
begin
  if Self.DialogEstablished then
    Self.Dialog.HandleMessage(Response);
end;

procedure TIdSipSession.AddOpenTransaction(Request: TIdSipRequest);
var
  NewRequest: TIdSipRequest;
begin
  Self.OpenTransactionLock.Acquire;
  try
    NewRequest := TIdSipRequest.Create;
    NewRequest.Assign(Request);
    Self.OpenTransactions.Add(NewRequest);
  finally
    Self.OpenTransactionLock.Release;
  end;
end;

function TIdSipSession.CreateNewAttempt(Challenge: TIdSipResponse): TIdSipRequest;
begin
  Result := Self.UA.CreateInvite(Challenge.ToHeader,
                                 Self.CurrentRequest.Body,
                                 Self.CurrentRequest.ContentType);
end;

function TIdSipSession.GetInvite: TIdSipRequest;
begin
  Result := Self.CurrentRequest;
end;

procedure TIdSipSession.MarkAsTerminated;
begin
  inherited MarkAsTerminated;

  ApplyTo(Self.OpenTransactions,
          Self.OpenTransactionLock,
          Self.MarkAsTerminatedProc);
end;

procedure TIdSipSession.NotifyOfEndedSession(const Reason: String);
var
  Notification: TIdSipEndedSessionMethod;
begin
  Notification := TIdSipEndedSessionMethod.Create;
  try
    Notification.Reason  := Reason;
    Notification.Session := Self;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;

  Self.UA.RemoveAction(Self);
end;

procedure TIdSipSession.NotifyOfEstablishedSession;
var
  Notification: TIdSipEstablishedSessionMethod;
begin
  Notification := TIdSipEstablishedSessionMethod.Create;
  try
    Notification.Session := Self;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipSession.NotifyOfFailure(Response: TIdSipResponse);
begin
  Self.MarkAsTerminated;
  Self.NotifyOfEndedSession(Response.Description);
end;

procedure TIdSipSession.SendBye;
var
  Bye: TIdSipRequest;
begin
  Bye := Self.UA.CreateBye(Self.Dialog);
  try
    // TODO: Verify this as correct behaviour. Otherwise we must use SIP discovery stuff
    Bye.LastHop.Transport := Self.CurrentRequest.LastHop.Transport;

    // We don't listen to the new transaction because we assume the BYE
    // succeeds immediately.
    Self.SendRequest(Bye);
  finally
    Bye.Free;
  end;
end;

//* TIdSipSession Private methods **********************************************

procedure TIdSipSession.MarkAsTerminatedProc(ObjectOrIntf: Pointer);
begin
  Self.TerminateOpenTransaction(TIdSipRequest(ObjectOrIntf));
end;

procedure TIdSipSession.NotifyOfModifiedSession(Invite: TIdSipRequest);
var
  Notification: TIdSipModifiedSessionMethod;
begin
  Notification := TIdSipModifiedSessionMethod.Create;
  try
    Notification.Session := Self;
    Notification.Request := Invite;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipSession.ProcessBye(Request: TIdSipRequest);
var
  OK: TIdSipResponse;
begin
  Self.MarkAsTerminated;
  Self.Dialog.HandleMessage(Request);

  OK := Self.UA.CreateResponse(Request, SIPOK);
  try
    Self.SendResponse(OK);
  finally
    OK.Free;
  end;
  Self.NotifyOfEndedSession(RemoteHangUp);
end;

procedure TIdSipSession.RejectOutOfOrderRequest(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UA.CreateResponse(Request,
                                     SIPInternalServerError);
  try
    Response.StatusText := RSSIPRequestOutOfOrder;
    Self.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipSession.RejectRequest(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UA.CreateResponse(Request,
                                     SIPRequestTerminated);
  try
    Self.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipSession.TerminateOpenTransaction(Request: TIdSipRequest);
begin
  Self.RejectRequest(Request);
end;

//******************************************************************************
//* TIdSipInboundSession                                                       *
//******************************************************************************
//* TIdSipInboundSession Public methods ****************************************

constructor TIdSipInboundSession.Create(UA: TIdSipUserAgentCore;
                                        Invite: TIdSipRequest;
                                        UsingSecureTransport: Boolean);
begin
  inherited Create(UA);

  Self.CurrentRequest.Assign(Invite);

  Self.UsingSecureTransport := UsingSecureTransport;

  Self.OkTimer := TIdSipSessionTimer.Create(Self, DefaultT1, DefaultT2);
end;

destructor TIdSipInboundSession.Destroy;
begin
  Self.OkTimer.Free;

  Self.LastResponse.Free;

  inherited Destroy;
end;

function TIdSipInboundSession.AcceptCall(const Offer, ContentType: String): String;
var
  OkResponse: TIdSipResponse;
begin
  // The type of payload processor depends on the ContentType passed in!
  OkResponse := Self.UA.CreateResponse(Self.CurrentRequest, SIPOK);
  try
    OkResponse.Body := Offer;
    Result := OkResponse.Body;

    OkResponse.ContentLength := Length(OkResponse.Body);
    OkResponse.ContentType   := ContentType;
    OkResponse.ToHeader.Tag  := Self.UA.NextTag;

    Self.DialogLock.Acquire;
    try
      if not Self.DialogEstablished then begin
        fDialog := Self.CreateInboundDialog(OkResponse);
        Self.NotifyOfEstablishedSession;
      end;

      Self.Dialog.HandleMessage(Self.CurrentRequest);
      Self.Dialog.HandleMessage(OkResponse);
    finally
      Self.DialogLock.Release;
    end;
    Self.SendResponse(OkResponse);
    Self.OkTimer.Start;
  finally
    OkResponse.Free;
  end;

  Self.FullyEstablished := true;
end;

procedure TIdSipInboundSession.ForwardCall(NewDestination: TIdSipAddressHeader);
var
  RedirectResponse: TIdSipResponse;
begin
  RedirectResponse := TIdSipResponse.InResponseTo(Self.CurrentRequest,
                                                  SIPMovedTemporarily);
  try
    RedirectResponse.AddHeader(ContactHeaderFull).Value := NewDestination.FullValue;
    Self.SendResponse(RedirectResponse);
  finally
    RedirectResponse.Free;
  end;

  Self.NotifyOfEndedSession(CallForwarded);
end;

function TIdSipInboundSession.IsInboundCall: Boolean;
begin
  Result := true;
end;

procedure TIdSipInboundSession.ReceiveRequest(Request: TIdSipRequest);
begin
  if Request.IsAck then begin
    Self.fReceivedAck := true;

    if Assigned(Self.OkTimer) then
      Self.OkTimer.Stop;
  end
  else
    inherited ReceiveRequest(Request);
end;

procedure TIdSipInboundSession.RejectCallBusy;
var
  BusyHereResponse: TIdSipResponse;
begin
  BusyHereResponse := TIdSipResponse.InResponseTo(Self.CurrentRequest,
                                                  SIPBusyHere);
  try
    Self.SendResponse(BusyHereResponse);
  finally
    BusyHereResponse.Free;
  end;

  Self.NotifyOfEndedSession(BusyHere);
end;

procedure TIdSipInboundSession.ResendLastResponse;
begin
  if Assigned(Self.LastResponse) then
    Self.SendResponse(Self.LastResponse);
end;

procedure TIdSipInboundSession.Terminate;
begin
  inherited Terminate;

  if Self.FullyEstablished then
    Self.SendBye
  else
    Self.TerminatePendingInvite;

  Self.NotifyOfEndedSession(LocalHangUp);
end;

procedure TIdSipInboundSession.TimeOut;
var
  Response: TIdSipResponse;
begin
  if not Self.FullyEstablished then begin
    Self.MarkAsTerminated;

    Response := Self.UA.CreateResponse(Self.CurrentRequest,
                                       SIPRequestTerminated);
    try
      Self.SendResponse(Response);
    finally
      Response.Free;
    end;

    Self.NotifyOfEndedSession(InviteTimeout);
  end;
end;

//* TIdSipInboundSession Protected methods *************************************

function TIdSipInboundSession.CreateDialogIDFrom(Msg: TIdSipMessage): TIdSipDialogID;
begin
  Result := TIdSipDialogID.Create(Msg.CallID,
                                  Msg.ToHeader.Tag,
                                  Msg.From.Tag);
end;

//* TIdSipInboundSession Private methods ***************************************

function TIdSipInboundSession.CreateInboundDialog(Response: TIdSipResponse): TIdSipDialog;
begin
  Result := TIdSipDialog.CreateInboundDialog(Self.CurrentRequest,
                                             Response,
                                             Self.UsingSecureTransport);

  Self.LastResponse := TIdSipResponse.Create;
  Self.LastResponse.Assign(Response);
end;

procedure TIdSipInboundSession.TerminatePendingInvite;
var
  TerminateResponse: TIdSipResponse;
begin
  TerminateResponse := Self.UA.CreateResponse(Self.CurrentRequest,
                                              SIPBusyHere);
  try
    Self.SendResponse(TerminateResponse);
  finally
    TerminateResponse.Free;
  end;
end;

//******************************************************************************
//* TIdSipOutboundSession                                                      *
//******************************************************************************
//* TIdSipOutboundSession Public methods ***************************************

constructor TIdSipOutboundSession.Create(UA: TIdSipUserAgentCore);
begin
  inherited Create(UA);

  Self.Initialize;
end;

constructor TIdSipOutboundSession.Create(UA: TIdSipUserAgentCore;
                                         Invite: TIdSipRequest);
begin
  inherited Create(UA);

  Self.Initialize;

  Self.CurrentRequest.Assign(Invite);
  Self.CurrentRequest.ToHeader.Tag := '';
end;

procedure TIdSipOutboundSession.Call(Dest: TIdSipAddressHeader;
                                     const InitialOffer: String;
                                     const MimeType: String);
var
  Invite: TIdSipRequest;
begin
  if not Self.InCall then begin
    Self.InCall := true;

    Invite := Self.UA.CreateInvite(Dest, InitialOffer, MimeType);
    try
      Self.CurrentRequest.Assign(Invite);
      Self.SendRequest(Self.CurrentRequest);
    finally
      Invite.Free;
    end;
  end;
end;

procedure TIdSipOutboundSession.Cancel;
begin
  if Self.FullyEstablished then Exit;

  Self.SendCancel;
  Self.TerminateAfterSendingCancel;
end;

function TIdSipOutboundSession.CanForkOn(Response: TIdSipResponse): Boolean;
begin
  Result := (Self.CurrentRequest.CallID = Response.CallID)
        and (Self.CurrentRequest.From.Tag = Response.From.Tag);
end;

function TIdSipOutboundSession.Fork(OkResponse: TIdSipResponse): TIdSipOutboundSession;
begin
  Result := TIdSipOutboundSession.Create(Self.UA, Self.CurrentRequest);
end;

function TIdSipOutboundSession.IsInboundCall: Boolean;
begin
  Result := false;
end;

procedure TIdSipOutboundSession.Terminate;
begin
  // The contorted logic below breaks down like this:
  // If we've established a session, things work as expected and we send a BYE
  // and commit suicide via NotifyOfEndedSession.
  // If we send an INVITE we MUST NOT send a CANCEL until we've received at
  // least one response from the remote end. That means that while we have
  // started terminating, we have not finished, and cannot until we've
  // received a response.
  if Self.FullyEstablished then begin
    Self.MarkAsTerminated;
    Self.SendBye;
    Self.NotifyOfEndedSession(LocalHangUp);
  end
  else
    Self.Cancel;
end;

//* TIdSipOutboundSession Protected methods ************************************

function TIdSipOutboundSession.CreateDialogIDFrom(Msg: TIdSipMessage): TIdSipDialogID;
begin
  if Msg.IsRequest then
    Result := TIdSipDialogID.Create(Msg.CallID,
                                    Msg.ToHeader.Tag,
                                    Msg.From.Tag)
  else
    Result := TIdSipDialogID.Create(Msg.CallID,
                                    Msg.From.Tag,
                                    Msg.ToHeader.Tag);
end;


function TIdSipOutboundSession.ReceiveOKResponse(Response: TIdSipResponse;
                                                 UsingSecureTransport: Boolean): Boolean;
begin
  // REMEMBER: A 2xx response to an INVITE DOES NOT take place in a transaction!
  // A 2xx response immediately terminates a client INVITE transaction so that
  // the ACK can get passed up to the UA (as an unhandled request).

  Self.DialogLock.Acquire;
  try
    if not Self.DialogEstablished then begin
      fDialog := Self.CreateOutboundDialog(Response, UsingSecureTransport);
      Self.NotifyOfEstablishedSession;
    end;
  finally
    Self.DialogLock.Release;
  end;

  Self.SendAck(Response);

  Result := true;
  Self.FullyEstablished := true;
end;

function TIdSipOutboundSession.ReceiveProvisionalResponse(Response: TIdSipResponse;
                                                          UsingSecureTransport: Boolean): Boolean;
begin
  // We should check for "and Response.ToHeader.HasTag" but that would prevent
  // us connecting to X-Lite, the non-compliant SIP phone.
  if not Response.IsTrying and Response.ToHeader.HasTag then begin
    Self.DialogLock.Acquire;
    try
      if not Self.DialogEstablished then begin
        fDialog := Self.CreateOutboundDialog(Response, UsingSecureTransport);
        Self.NotifyOfEstablishedSession;
      end;
    finally
      Self.DialogLock.Release;
    end;
  end;

  Result := true;
end;

function TIdSipOutboundSession.ReceiveRedirectionResponse(Response: TIdSipResponse;
                                                          UsingSecureTransport: Boolean): Boolean;
begin
  Result := false;

  if Response.HasHeader(ContactHeaderFull) then begin
    Self.UA.Call(Response.FirstContact,
                 Self.CurrentRequest.Body,
                 Self.CurrentRequest.ContentType);
    Result := true;
  end;
end;

procedure TIdSipOutboundSession.SendBye;
begin
  inherited SendBye;

  Self.MarkAsTerminated;
//  Self.NotifyOfEndedSession(LocalHangUp);
end;

//* TIdSipOutboundSession Private methods **************************************

function TIdSipOutboundSession.CreateOutboundDialog(Response: TIdSipResponse;
                                                    UsingSecureTransport: Boolean): TIdSipDialog;
begin
  Self.UsingSecureTransport := UsingSecureTransport;

  Result := TIdSipDialog.CreateOutboundDialog(Self.CurrentRequest,
                                              Response,
                                              Self.UsingSecureTransport);

  Self.NotifyOfEstablishedSession;
end;

procedure TIdSipOutboundSession.Initialize;
begin
  Self.InCall := false;
end;

procedure TIdSipOutboundSession.SendAck(Final: TIdSipResponse);
var
  Ack: TIdSipRequest;
begin
  Assert(Self.Dialog <> nil, 'Dialog not established when we send the ACK');

  Ack := Self.UA.CreateAck(Self.Dialog);
  try
    Ack.Body := Self.CurrentRequest.Body;
    Ack.ContentDisposition.Value := DispositionSession;
    Ack.ContentLength := Length(Ack.Body);
    Ack.ContentType := Self.CurrentRequest.ContentType;

    if Self.CurrentRequest.HasAuthorization then
      Ack.FirstAuthorization.Value := Self.CurrentRequest.FirstAuthorization.FullValue;
    if Self.CurrentRequest.HasProxyAuthorization then
      Ack.FirstProxyAuthorization.Value := Self.CurrentRequest.FirstProxyAuthorization.FullValue;

    Self.SendRequest(Ack);
  finally
    Ack.Free;
  end;
end;

procedure TIdSipOutboundSession.SendCancel;
var
  Cancel: TIdSipRequest;
begin
  Cancel := Self.CurrentRequest.CreateCancel;
  try
    Self.SendRequest(Cancel);
  finally
    Cancel.Free;
  end;
end;

procedure TIdSipOutboundSession.TerminateAfterSendingCancel;
begin
  Self.MarkAsTerminated;
  Self.NotifyOfEndedSession(LocalCancel);
end;

//******************************************************************************
//* TIdSipOptions                                                              *
//******************************************************************************
//* TIdSipOptions Public methods ***********************************************

class function TIdSipOptions.Method: String;
begin
  Result := MethodOptions;
end;

function TIdSipOptions.IsOptions: Boolean;
begin
  Result := true;
end;

procedure TIdSipOptions.Terminate;
begin
  Self.UA.RemoveAction(Self);
end;

//* TIdSipOptions Protected methods ********************************************

function TIdSipOptions.CreateNewAttempt(Challenge: TIdSipResponse): TIdSipRequest;
var
  TempTo: TIdSipToHeader;
begin
  TempTo := TIdSipToHeader.Create;
  try
    TempTo.Address := Self.CurrentRequest.RequestUri;

    Result := Self.UA.CreateOptions(TempTo);
  finally
    TempTo.Free;
  end;
end;

//******************************************************************************
//* TIdSipInboundOptions                                                       *
//******************************************************************************
//* TIdSipInboundOptions Public methods ****************************************

constructor TIdSipInboundOptions.Create(UA: TIdSipUserAgentCore;
                                        Options: TIdSipRequest);
begin
  inherited Create(UA);

  Self.CurrentRequest.Assign(Options);
end;

procedure TIdSipInboundOptions.ReceiveRequest(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UA.CreateResponse(Request, Self.UA.ResponseForInvite);
  try
    Response.AddHeader(AcceptHeader).Value := Self.UA.AllowedContentTypes;
    Response.AddHeader(AllowHeader).Value  := Self.UA.AllowedMethods;
    Response.AddHeader(AcceptEncodingHeader).Value := Self.UA.AllowedEncodings;
    Response.AddHeader(AcceptLanguageHeader).Value := Self.UA.AllowedLanguages;
    Response.AddHeader(SupportedHeaderFull).Value := Self.UA.AllowedExtensions;
    Response.AddHeader(ContactHeaderFull).Assign(Self.UA.Contact);

    // For OPTIONS "traceroute"-like functionality. cf RFC 3261, section 11.2
    Response.FirstWarning.Code  := WarningMisc;
    Response.FirstWarning.Agent := Self.UA.HostName;
    Response.FirstWarning.Text  := '';

    Self.SendResponse(Response);
  finally
    Response.Free;
  end;

  Self.Terminate;
end;

//******************************************************************************
//* TIdSipOutboundOptions                                                      *
//******************************************************************************
//* TIdSipOutboundOptions Public methods ***************************************

procedure TIdSipOutboundOptions.AddListener(const Listener: IIdSipOptionsListener);
begin
  Self.Listeners.AddListener(Listener);
end;

procedure TIdSipOutboundOptions.QueryOptions(Server: TIdSipAddressHeader);
var
  Options: TIdSipRequest;
begin
  Options := Self.UA.CreateOptions(Server);
  try
    Self.CurrentRequest.Assign(Options);
    Self.SendRequest(Options);
  finally
    Options.Free;
  end;
end;

procedure TIdSipOutboundOptions.RemoveListener(const Listener: IIdSipOptionsListener);
begin
  Self.Listeners.RemoveListener(Listener);
end;

//* TIdSipOutboundOptions Protected methods ************************************

procedure TIdSipOutboundOptions.ActionSucceeded(Response: TIdSipResponse);
begin
  Self.NotifyOfSuccess(Response);
end;

//* TIdSipOutboundOptions Private methods **************************************

procedure TIdSipOutboundOptions.NotifyOfSuccess(Response: TIdSipResponse);
var
  CurrentBindings: TIdSipContacts;
  Notification:    TIdSipOptionsSuccessMethod;
begin
  CurrentBindings := TIdSipContacts.Create(Response.Headers);
  try
    Notification := TIdSipOptionsSuccessMethod.Create;
    try
      Notification.Options  := Self;
      Notification.Response := Response;

      Self.Listeners.Notify(Notification);
    finally
      Notification.Free;
    end;
  finally
    CurrentBindings.Free;
  end;

  Self.Terminate;
end;

//******************************************************************************
//* TIdSipRegistration                                                         *
//******************************************************************************
//* TIdSipRegistration Public methods ******************************************

class function TIdSipRegistration.Method: String;
begin
  Result := MethodRegister;
end;

function TIdSipRegistration.IsRegistration: Boolean;
begin
  Result := true;
end;

procedure TIdSipRegistration.Terminate;
begin
  Self.UA.RemoveAction(Self);
end;

//* TIdSipRegistration Protected methods ***************************************

function TIdSipRegistration.CreateNewAttempt(Challenge: TIdSipResponse): TIdSipRequest;
var
  TempTo: TIdSipToHeader;
begin
  TempTo := TIdSipToHeader.Create;
  try
    TempTo.Address := Self.CurrentRequest.RequestUri;

    Result := Self.UA.CreateRegister(TempTo);
  finally
    TempTo.Free;
  end;
end;

//******************************************************************************
//* TIdSipInboundRegistration                                                  *
//******************************************************************************
//* TIdSipInboundRegistration Public methods ***********************************

constructor TIdSipInboundRegistration.Create(UA: TIdSipUserAgentCore;
                                             Reg: TIdSipRequest);
begin
  inherited Create(UA);

  Self.CurrentRequest.Assign(Reg);
end;

procedure TIdSipInboundRegistration.ReceiveRequest(Request: TIdSipRequest);
var
  Bindings: TIdSipContacts;
  Date:     TIdSipDateHeader;
  Response: TIdSipResponse;
begin
  if not Self.AcceptRequest(Request) then Exit;

  if (Request.ContactCount = 1)
    and Request.FirstContact.IsWildCard
    and (Request.QuickestExpiry = 0) then begin

    if not Self.BindingDB.RemoveAllBindings(Request) then
      Self.RejectFailedRequest(Request)
    else
      Self.RejectRequest(Request, SIPOK);
    Exit;
  end;

  if not Self.BindingDB.AddBindings(Request) then begin
    Self.RejectFailedRequest(Request);
    Exit;
  end;

  Bindings := TIdSipContacts.Create;
  try
    if Self.BindingDB.BindingsFor(Request,
                                  Bindings) then begin
      Response := Self.UA.CreateResponse(Request, SIPOK);
      try
        Response.AddHeaders(Bindings);

        Date := TIdSipDateHeader.Create;
        try
          Date.Time.SetFromTDateTime(Now);
          Response.AddHeader(Date);
        finally
          Date.Free;
        end;

        Self.SendResponse(Response);
      finally
        Response.Free;
      end;
    end
    else begin
      Self.RejectFailedRequest(Request);
    end;
  finally
    Bindings.Free;
  end;

  Self.Terminate;
end;

//* TIdSipInboundRegistration Private methods **********************************

function TIdSipInboundRegistration.AcceptRequest(Request: TIdSipRequest): Boolean;
begin
  // cf RFC 3261 section 10.3
  // Steps 1, 2 & 3 - covered by Self.UA
  Result := true;

  // Step 4
  if not Self.BindingDB.IsAuthorized(Request.From) then begin
    Self.RejectForbidden(Request);
    Result := false;
    Exit;
  end;

  // Step 5
  if not Self.BindingDB.IsValid(Request) then begin
    Self.RejectNotFound(Request);
    Result := false;
    Exit;
  end;

  // Step 6 (or part thereof)
  if Request.HasHeader(ContactHeaderFull) then begin
    if Request.FirstContact.IsWildCard then begin
      if (Request.ContactCount > 1) then begin
        Self.RejectRequest(Request, SIPBadRequest);
        Result := false;
        Exit;
      end;

      if Request.FirstContact.WillExpire
        and (Request.FirstContact.Expires = 0) then
          Result := true
      else begin
        Self.RejectRequest(Request, SIPBadRequest);
        Result := false;
        Exit;
      end;
    end
    else if Request.HasExpiry and (Request.QuickestExpiry < Self.UA.MinimumExpiryTime) then begin
      Self.RejectExpireTooBrief(Request);
      Result := false;
    end;
  end;

  // Steps 7 & 8 in ReceiveRequest
end;

function TIdSipInboundRegistration.BindingDB: TIdSipAbstractBindingDatabase;
begin
  Result := Self.UA.BindingDB;
end;

procedure TIdSipInboundRegistration.RejectExpireTooBrief(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UA.CreateResponse(Request, SIPIntervalTooBrief);
  try
    Response.AddHeader(MinExpiresHeader).Value := IntToStr(Self.UA.MinimumExpiryTime);
    Self.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipInboundRegistration.RejectFailedRequest(Request: TIdSipRequest);
begin
  Self.RejectRequest(Request, SIPInternalServerError);
end;

procedure TIdSipInboundRegistration.RejectForbidden(Request: TIdSipRequest);
begin
  Self.RejectRequest(Request, SIPForbidden);
end;

procedure TIdSipInboundRegistration.RejectNotFound(Request: TIdSipRequest);
begin
  Self.RejectRequest(Request, SIPNotFound);
end;

procedure TIdSipInboundRegistration.RejectRequest(Request: TIdSipRequest;
                                                  StatusCode: Cardinal);
var
  Response: TIdSipResponse;
begin
  Response := Self.UA.CreateResponse(Request, StatusCode);
  try
    Self.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

//******************************************************************************
//* TIdSipOutboundRegistration                                                 *
//******************************************************************************
//* TIdSipOutboundRegistration Public methods **********************************

constructor TIdSipOutboundRegistration.Create(UA: TIdSipUserAgentCore);
begin
  inherited Create(UA);

  Self.Bindings := TIdSipContacts.Create;
end;

destructor TIdSipOutboundRegistration.Destroy;
begin
  Self.Bindings.Free;

  inherited Destroy;
end;

procedure TIdSipOutboundRegistration.AddListener(const Listener: IIdSipRegistrationListener);
begin
  Self.Listeners.AddListener(Listener);
end;

procedure TIdSipOutboundRegistration.FindCurrentBindings(Registrar: TIdSipUri);
var
  BlankBindings: TIdSipContacts;
begin
  BlankBindings := TIdSipContacts.Create;
  try
    Self.RegisterWith(Registrar, BlankBindings);
  finally
    BlankBindings.Free;
  end;
end;

procedure TIdSipOutboundRegistration.RegisterWith(Registrar: TIdSipUri; Bindings: TIdSipContacts);
var
  Request: TIdSipRequest;
begin
  Request := Self.CreateRegister(Registrar, Bindings);
  try
    Self.Bindings.Clear;
    Self.Bindings.Add(Bindings);

    Self.SendRequest(Request);
  finally
    Request.Free;
  end;
end;

procedure TIdSipOutboundRegistration.RegisterWith(Registrar: TIdSipUri; Contact: TIdSipContactHeader);
var
  Binding: TIdSipContacts;
begin
  Binding := TIdSipContacts.Create;
  try
    Binding.Add(Contact);

    Self.RegisterWith(Registrar, Binding);
  finally
    Binding.Free;
  end;
end;

procedure TIdSipOutboundRegistration.RemoveListener(const Listener: IIdSipRegistrationListener);
begin
  Self.Listeners.RemoveListener(Listener);
end;

procedure TIdSipOutboundRegistration.Unregister(Registrar: TIdSipUri);
var
  RemovalBindings: TIdSipContacts;
  Request:         TIdSipRequest;
begin
  RemovalBindings := TIdSipContacts.Create;
  try
    Self.Bindings.Clear;
    Self.Bindings.Add(ContactHeaderFull);
    Self.Bindings.First;
    Self.Bindings.CurrentContact.IsWildCard := true;

    Request := Self.CreateRegister(Registrar, Bindings);
    try
      Request.FirstExpires.NumericValue := 0;

      Self.SendRequest(Request);
    finally
      Request.Free;
    end;
  finally
    RemovalBindings.Free;
  end;
end;

//* TIdSipOutboundRegistration Protected methods *******************************

procedure TIdSipOutboundRegistration.ActionSucceeded(Response: TIdSipResponse);
begin
  Self.NotifyOfSuccess(Response);
end;

procedure TIdSipOutboundRegistration.NotifyOfFailure(Response: TIdSipResponse);
var
  CurrentBindings: TIdSipContacts;
  Notification:    TIdSipRegistrationFailedMethod;
begin
  CurrentBindings := TIdSipContacts.Create(Response.Headers);
  try
    Notification := TIdSipRegistrationFailedMethod.Create;
    try
      Notification.CurrentBindings := CurrentBindings;
      Notification.Reason          := Response.Description;
      Notification.Registration    := Self;

      Self.Listeners.Notify(Notification);
    finally
      Notification.Free;
    end;
  finally
    CurrentBindings.Free;
  end;

  Self.Terminate;
end;

function TIdSipOutboundRegistration.ReceiveFailureResponse(Response: TIdSipResponse): Boolean;
begin
  Result := not inherited ReceiveFailureResponse(Response);
  
  if Result then begin
    case Response.StatusCode of
      SIPIntervalTooBrief: begin
        Self.ReissueRequest(Self.CurrentRequest.RequestUri,
                            Response.FirstMinExpires.NumericValue);
        Result := true;
      end;

      SIPBadExtension: begin
        Result := Self.CurrentRequest.HasHeader(RequireHeader);
        if Result then
          Self.RetryWithoutExtensions(Self.CurrentRequest.RequestUri,
                                      Response);
      end;
    else
      Result := false;
    end;
  end;
end;

function TIdSipOutboundRegistration.ReceiveRedirectionResponse(Response: TIdSipResponse;
                                                               UsingSecureTransport: Boolean): Boolean;
begin
  Result := false;

  if Response.HasHeader(ContactHeaderFull) then begin
    Self.UA.RegisterWith(Response.FirstContact.Address);

    Result := true;
  end;
end;

procedure TIdSipOutboundRegistration.SendRequest(Request: TIdSipRequest);
begin
  Self.CurrentRequest.Assign(Request);

  inherited SendRequest(Request);
end;

//* TIdSipOutboundRegistration Private methods *********************************

function TIdSipOutboundRegistration.CreateRegister(Registrar: TIdSipUri;
                                                   Bindings: TIdSipContacts): TIdSipRequest;
var
  OldContacts: TIdSipContacts;
  ToHeader: TIdSipToHeader;
begin
  ToHeader := TIdSipToHeader.Create;
  try
    ToHeader.Address := Registrar;

    Result := Self.UA.CreateRegister(ToHeader);

    // Bindings explicitly carries all Contact information. Thus we must remove
    // any Contact information already in Result.
    OldContacts := TIdSipContacts.Create(Result.Headers);
    try
      OldContacts.Clear;
    finally
      OldContacts.Free;
    end;

    Result.AddHeaders(Bindings);
  finally
    ToHeader.Free;
  end;
end;

procedure TIdSipOutboundRegistration.NotifyOfSuccess(Response: TIdSipResponse);
var
  CurrentBindings: TIdSipContacts;
  Notification:    TIdSipRegistrationSucceededMethod;
begin
  CurrentBindings := TIdSipContacts.Create(Response.Headers);
  try
    Notification := TIdSipRegistrationSucceededMethod.Create;
    try
      Notification.CurrentBindings := CurrentBindings;
      Notification.Registration    := Self;

      Self.Listeners.Notify(Notification);
    finally
      Notification.Free;
    end;
  finally
    CurrentBindings.Free;
  end;

  Self.Terminate;
end;

procedure TIdSipOutboundRegistration.ReissueRequest(Registrar: TIdSipUri;
                                            MinimumExpiry: Cardinal);
var
  Bindings: TIdSipContacts;
  Request: TIdSipRequest;
begin
  // We received a 423 Interval Too Brief from the registrar. Therefore we
  // make a new REGISTER request with the registrar's minimum expiry.
  Request := Self.CreateRegister(Registrar, Self.Bindings);
  try
    Bindings := TIdSipContacts.Create(Request.Headers);
    try
      Bindings.First;
      while Bindings.HasNext do begin
        if Bindings.CurrentContact.WillExpire then
          Bindings.CurrentContact.Expires := Max(Bindings.CurrentContact.Expires,
                                                     MinimumExpiry);
        Bindings.Next;
      end;
    finally
      Bindings.Free;
    end;

    Request.FirstExpires.NumericValue := MinimumExpiry;
    Self.SendRequest(Request);
  finally
    Request.Free;
  end;
end;

procedure TIdSipOutboundRegistration.RetryWithoutExtensions(Registrar: TIdSipUri;
                                                    Response: TIdSipResponse);
var
  Bindings: TIdSipContacts;
  Request: TIdSipRequest;
begin
  Bindings := TIdSipContacts.Create;
  try
    Bindings.Add(Self.UA.Contact);

    Request := Self.CreateRegister(Registrar, Bindings);
    try
      if not Response.HasHeader(UnsupportedHeader) then begin
        // A 420 Bad Extension MUST have an unsupported header. In the
        // interests of accepting liberally though, we just drop all
        // Requires.
        Request.RemoveAllHeadersNamed(RequireHeader);
      end
      else
        Request.FirstRequire.RemoveValues(Response.FirstUnsupported);

      Self.SendRequest(Request);
    finally
      Request.Free;
    end;
  finally
    Bindings.Free;
  end;
end;

//******************************************************************************
//* TIdSipOptionsFailureMethod                                                 *
//******************************************************************************
//* TIdSipOptionsFailureMethod Public methods **********************************

procedure TIdSipOptionsFailureMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipOptionsListener).OnFailure(Self.Options,
                                               Self.Response,
                                               Self.Reason);
end;

//******************************************************************************
//* TIdSipOptionsSuccessMethod                                                 *
//******************************************************************************
//* TIdSipOptionsSuccessMethod Public methods **********************************

procedure TIdSipOptionsSuccessMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipOptionsListener).OnSuccess(Self.Options,
                                               Self.Response);
end;

//******************************************************************************
//* TIdSipRegistrationFailedMethod                                             *
//******************************************************************************
//* TIdSipRegistrationFailedMethod Public methods ******************************

procedure TIdSipRegistrationFailedMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipRegistrationListener).OnFailure(Self.Registration,
                                                    Self.CurrentBindings,
                                                    Self.Reason);
end;

//******************************************************************************
//* TIdSipRegistrationSucceededMethod                                          *
//******************************************************************************
//* TIdSipRegistrationSucceededMethod Public methods ***************************

procedure TIdSipRegistrationSucceededMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipRegistrationListener).OnSuccess(Self.Registration,
                                                    Self.CurrentBindings);
end;

//******************************************************************************
//* TIdSipUserAgentDroppedUnmatchedResponseMethod                              *
//******************************************************************************
//* TIdSipUserAgentDroppedUnmatchedResponseMethod Public methods ***************

procedure TIdSipUserAgentDroppedUnmatchedResponseMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipUserAgentListener).OnDroppedUnmatchedResponse(Self.Response,
                                                                  Self.Receiver);
end;

//******************************************************************************
//* TIdSipUserAgentInboundCallMethod                                           *
//******************************************************************************
//* TIdSipUserAgentInboundCallMethod Public methods ****************************

procedure TIdSipUserAgentInboundCallMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipUserAgentListener).OnInboundCall(Self.Session);
end;

end.
