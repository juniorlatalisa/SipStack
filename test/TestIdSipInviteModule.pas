unit TestIdSipInviteModule;

interface

uses
  Classes, IdRtp, IdSdp, IdSipCore, IdSipDialog, IdSipInviteModule,
  IdSipLocator, IdSipMessage, IdSipSubscribeModule, IdSipTransport,
  IdSipUserAgent, IdTimerQueue, TestFrameworkSip, TestFrameworkSipTU;

type
  // This class attempts to isolate an intermittent bug that surfaces in the
  // TearDown of TestTerminateDuringRedirect.
  TestDebug = class(TTestCaseTU,
                    IIdSipActionListener,
                    IIdSipSessionListener)
  private
    FailReason: String;
    Session:    TIdSipOutboundSession;

    procedure OnAuthenticationChallenge(Action: TIdSipAction;
                                        Response: TIdSipResponse);
    procedure OnEndedSession(Session: TIdSipSession;
                             ErrorCode: Cardinal;
                             const Reason: String);
    procedure OnEstablishedSession(Session: TIdSipSession;
                                   const RemoteSessionDescription: String;
                                   const MimeType: String);
    procedure OnModifySession(Session: TIdSipSession;
                              const RemoteSessionDescription: String;
                              const MimeType: String);
    procedure OnModifiedSession(Session: TIdSipSession;
                                Answer: TIdSipResponse);
    procedure OnNetworkFailure(Action: TIdSipAction;
                               ErrorCode: Cardinal;
                               const Reason: String);
    procedure OnProgressedSession(Session: TIdSipSession;
                                  Progress: TIdSipResponse);
    procedure OnReferral(Session: TIdSipSession;
                         Refer: TIdSipRequest);
    procedure ReceiveMovedTemporarily(Invite: TIdSipRequest;
                                      const Contacts: array of String); overload;
    procedure ReceiveMovedTemporarily(const Contacts: array of String); overload;
  public
    procedure SetUp; override;
  published
    procedure TestSendSetsInitialRequest;
    procedure TestTerminateDuringRedirect;
  end;

  TestTIdSipInviteModule = class(TTestCaseTU)
  private
    Dlg:    TIdSipDialog;
    Module: TIdSipInviteModule;
  public
    procedure SetUp; override;

    procedure CheckCommaSeparatedHeaders(const ExpectedValues: String;
                                         Header: TIdSipHeader;
                                         const Msg: String);
    procedure CheckCreateRequest(Dest: TIdSipToHeader;
                                 Request: TIdSipRequest);
    function  ConvertListToHeader(List: TStrings): String;
  published
    procedure TestAddListener;
    procedure TestCreateAck;
    procedure TestCreateBye;
    procedure TestCreateInvite;
    procedure TestCreateInviteInsideDialog;
    procedure TestCreateInviteWithBody;
    procedure TestCreateInviteWithGruu;
    procedure TestCreateReInvite;
    procedure TestDoNotDisturb;
    procedure TestReceiveByeForUnmatchedDialog;
    procedure TestReceiveByeWithoutTags;
    procedure TestReceiveInviteWithMultipleReplacesHeaders;
    procedure TestReceiveInviteWithNoContactHeader;
    procedure TestRejectUnknownContentType;
    procedure TestRemoveListener;
    procedure TestReplaceCall;
  end;

  TestTIdSipInboundInvite = class(TestTIdSipAction,
                                  IIdSipInboundInviteListener)
  private
    Answer:         String;
    AnswerMimeType: String;
    Dialog:         TIdSipDialog;
    Failed:         Boolean;
    InviteAction:   TIdSipInboundInvite;
    Module:         TIdSipInviteModule;
    OnSuccessFired: Boolean;

    procedure CheckAck(InviteAction: TIdSipInboundInvite);
    procedure CheckAckWithDifferentCSeq(InviteAction: TIdSipInboundInvite);
    procedure OnFailure(InviteAgent: TIdSipInboundInvite);
    procedure OnSuccess(InviteAgent: TIdSipInboundInvite;
                        Ack: TIdSipRequest);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAccept;
    procedure TestCancelAfterAccept;
    procedure TestCancelBeforeAccept;
    procedure TestInviteWithNoOffer;
    procedure TestIsInbound; override;
    procedure TestIsInvite; override;
    procedure TestIsOptions; override;
    procedure TestIsRegistration; override;
    procedure TestIsSession; override;
    procedure TestLastResponse;
    procedure TestLocalGruu; override;
    procedure TestMatchAck;
    procedure TestMatchAckToReInvite;
    procedure TestMatchAckToReInviteWithDifferentCSeq;
    procedure TestMatchAckWithDifferentCSeq;
    procedure TestMethod;
    procedure TestNotifyOfNetworkFailure;
    procedure TestNotifyOfSuccess;
    procedure TestReceiveResentAck;
    procedure TestRedirectCall;
    procedure TestRedirectCallPermanent;
    procedure TestRejectCallBusy;
    procedure TestResendOk;
    procedure TestRing;
    procedure TestRingWithGruu;
    procedure TestSendSessionProgress;
    procedure TestSendSessionProgressWithGruu;
    procedure TestTerminateAfterAccept;
    procedure TestTerminateBeforeAccept;
    procedure TestTimeOut;
  end;

  TestTIdSipOutboundInvite = class(TestTIdSipAction,
                                   IIdSipInviteListener,
                                   IIdSipMessageModuleListener,
                                   IIdSipTransactionUserListener,
                                   IIdSipUserAgentListener)
  private
    Dialog:                   TIdSipDialog;
    DroppedUnmatchedResponse: Boolean;
    InviteMimeType:           String;
    InviteOffer:              String;
    OnCallProgressFired:      Boolean;
    OnDialogEstablishedFired: Boolean;
    OnFailureFired:           Boolean;
    OnRedirectFired:          Boolean;
    OnSuccessFired:           Boolean;
    ToHeaderTag:              String;

    procedure CheckReceiveFailed(StatusCode: Cardinal);
    procedure CheckReceiveOk(StatusCode: Cardinal);
    procedure CheckReceiveProvisional(StatusCode: Cardinal);
    procedure CheckReceiveRedirect(StatusCode: Cardinal);
    function  CreateArbitraryDialog: TIdSipDialog;
    procedure OnCallProgress(InviteAgent: TIdSipOutboundInvite;
                        Response: TIdSipResponse);
    procedure OnDialogEstablished(InviteAgent: TIdSipOutboundInvite;
                                  NewDialog: TidSipDialog);
    procedure OnDroppedUnmatchedMessage(UserAgent: TIdSipAbstractCore;
                                        Message: TIdSipMessage;
                                        Receiver: TIdSipTransport);
    procedure OnFailure(InviteAgent: TIdSipOutboundInvite;
                        Response: TIdSipResponse;
                        const Reason: String);
    procedure OnRedirect(Invite: TIdSipOutboundInvite;
                         Response: TIdSipResponse);
    procedure OnSuccess(InviteAgent: TIdSipOutboundInvite;
                        Response: TIdSipResponse);
  protected
    procedure CheckSendDialogEstablishingRequestWithGruu;
    function CreateInitialInvite: TIdSipOutboundInitialInvite;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAbandonAuthentication; override;
    procedure TestAddListener;
    procedure TestAnswerInAck;
    procedure TestCancelAfterAccept;
    procedure TestCancelBeforeAccept;
    procedure TestCancelBeforeProvisional;
    procedure TestCancelReceiveInviteOkBeforeCancelOk;
    procedure TestInviteTwice;
    procedure TestIsInvite; override;
    procedure TestMethod;
    procedure TestOfferInInvite;
    procedure TestReceive2xxSchedulesTransactionCompleted;
    procedure TestReceiveProvisional;
    procedure TestReceiveGlobalFailed;
    procedure TestReceiveOk;
    procedure TestReceiveRedirect;
    procedure TestReceiveRequestFailed;
    procedure TestReceiveRequestFailedAfterAckSent;
    procedure TestReceiveServerFailed;
    procedure TestRemoveListener;
    procedure TestSendTwice;
    procedure TestSendWithGruu; virtual;
    procedure TestTerminateBeforeAccept;
    procedure TestTerminateAfterAccept;
    procedure TestTransactionCompleted;
  end;

  TestTIdSipOutboundInitialInvite = class(TestTIdSipOutboundInvite)
  protected
    function CreateAction: TIdSipAction; override;
  published
    procedure TestSendWithGruu; override;
  end;

  TestTIdSipOutboundRedirectedInvite = class(TestTIdSipOutboundInvite)
  private
    function CreateInvite: TIdSipOutboundRedirectedInvite;
  protected
    function CreateAction: TIdSipAction; override;
  published
    procedure TestRedirectedInvite;
    procedure TestSendWithGruu; override;
  end;

  TestTIdSipOutboundReInvite = class(TestTIdSipOutboundInvite)
  private
    Dialog: TIdSipDialog;

    function CreateInvite: TIdSipOutboundReInvite;
  protected
    function CreateAction: TIdSipAction; override;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TestTIdSipOutboundReplacingInvite = class(TestTIdSipOutboundInvite)
  private
    CallID:  String;
    FromTag: String;
    ToTag:   String;

    function CreateInvite: TIdSipOutboundReplacingInvite;
  protected
    function CreateAction: TIdSipAction; override;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSend;
  end;

  TestTIdSipSession = class(TestTIdSipAction,
                            IIdSipSessionListener,
                            IIdSipTransactionUserListener,
                            IIdSipUserAgentListener)
  protected
    DroppedUnmatchedResponse:  Boolean;
    ErrorCode:                 Cardinal;
    MimeType:                  String;
    Module:                    TIdSipInviteModule;
    MultiStreamSdp:            TIdSdpPayload;
    OnEndedSessionFired:       Boolean;
    OnEstablishedSessionFired: Boolean;
    OnModifiedSessionFired:    Boolean;
    OnModifySessionFired:      Boolean;
    OnReferralFired:           Boolean;
    Reason:                    String;
    RemoteSessionDescription:  String;
    SimpleSdp:                 TIdSdpPayload;

    procedure CheckHeadersEqual(ExpectedMessage: TIdSipMessage;
                                ReceivedMessage: TIdSipMessage;
                                const HeaderName: String;
                                const Msg: String);
    procedure CheckResendWaitTime(Milliseconds: Cardinal;
                                  const Msg: String); virtual;
    function  CreateAndEstablishSession: TIdSipSession;
    function  CreateMultiStreamSdp: TIdSdpPayload;
    function  CreateRemoteReInvite(LocalDialog: TIdSipDialog): TIdSipRequest;
    function  CreateSimpleSdp: TIdSdpPayload;
    procedure EstablishSession(Session: TIdSipSession); virtual; abstract;
    procedure OnDroppedUnmatchedMessage(UserAgent: TIdSipAbstractCore;
                                        Message: TIdSipMessage;
                                        Receiver: TIdSipTransport);
    procedure OnEndedSession(Session: TIdSipSession;
                             ErrorCode: Cardinal;
                             const Reason: String); virtual;
    procedure OnEstablishedSession(Session: TIdSipSession;
                                   const RemoteSessionDescription: String;
                                   const MimeType: String); virtual;
    procedure OnModifiedSession(Session: TIdSipSession;
                                Answer: TIdSipResponse); virtual;
    procedure OnModifySession(Session: TIdSipSession;
                              const RemoteSessionDescription: String;
                              const MimeType: String); virtual;
    procedure OnProgressedSession(Session: TIdSipSession;
                                  Progress: TIdSipResponse); virtual;
    procedure OnReferral(Session: TIdSipSession;
                         Refer: TIdSipRequest);
    procedure ReceiveRemoteReInvite(Session: TIdSipSession);
    procedure ResendWith(Session: TIdSipSession;
                         AuthenticationChallenge: TIdSipResponse);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAckToInDialogInviteMatchesInvite;
    procedure TestByeCarriesInviteAuthorization;
    procedure TestDontMatchResponseToModify;
    procedure TestDontMatchResponseToInitialRequest;
    procedure TestInboundModify;
    procedure TestIsSession; override;
    procedure TestMatchBye;
    procedure TestMatchInitialRequest;
    procedure TestMatchInboundModify;
    procedure TestMatchInboundModifyAck;
    procedure TestMatchReferWithCorrectGridParameter;
    procedure TestMatchReferWithIncorrectGridParameter;
    procedure TestModify;
    procedure TestModifyBeforeFullyEstablished;
    procedure TestModifyDuringModification;
    procedure TestModifyGlareInbound;
    procedure TestModifyGlareOutbound;
    procedure TestModifyRejected;
    procedure TestModifyRejectedWithTimeout;
    procedure TestModifyWaitTime;
    procedure TestReceiveByeWithPendingRequests;
    procedure TestReceiveInDialogReferWithNoSubscribeModule;
    procedure TestReceiveInDialogRefer;
    procedure TestRejectInviteWhenInboundModificationInProgress;
    procedure TestRejectInviteWhenOutboundModificationInProgress;
    procedure TestRemodify;
  end;

  TestTIdSipInboundSession = class(TestTIdSipSession,
                                   IIdRTPDataListener,
                                   IIdSipInviteModuleListener,
                                   IIdSipMessageModuleListener,
                                   IIdSipTransportSendingListener,
                                   IIdSipUserAgentListener)
  private
    RemoteContentType:      String;
    RemoteDesc:             String;
    SentRequestTerminated:  Boolean;
    Session:                TIdSipInboundSession;

    procedure OnNewData(Data: TIdRTPPayload;
                        Binding: TIdConnection);
    procedure OnSendRequest(Request: TIdSipRequest;
                            Sender: TIdSipTransport;
                            Destination: TIdSipLocation);
    procedure OnSendResponse(Response: TIdSipResponse;
                             Sender: TIdSipTransport;
                             Destination: TIdSipLocation);
    procedure ReceiveAckWithBody(const SessionDesc,
                                 ContentType: String);
  protected
    procedure CheckResendWaitTime(Milliseconds: Cardinal;
                                  const Msg: String); override;
    function  CreateAction: TIdSipAction; override;
    procedure EstablishSession(Session: TIdSipSession); override;
    procedure OnEndedSession(Session: TIdSipSession;
                             ErrorCode: Cardinal;
                             const Reason: String); override;
    procedure OnEstablishedSession(Session: TIdSipSession;
                                   const RemoteSessionDescription: String;
                                   const MimeType: String); override;
    procedure OnInboundCall(UserAgent: TIdSipInviteModule;
                            Session: TIdSipInboundSession);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAcceptCall;
    procedure TestAcceptCallWithGruu;
    procedure TestAddSessionListener;
    procedure TestCancelAfterAccept;
    procedure TestCancelBeforeAccept;
    procedure TestCancelNotifiesSession;
    procedure TestInviteHasNoOffer;
    procedure TestInviteHasOffer;
    procedure TestIsInbound; override;
    procedure TestIsOutboundCall;
    procedure TestInviteWithReplaces;
    procedure TestLocalGruu; override;
    procedure TestMethod;
    procedure TestNotifyListenersOfEstablishedSession;
    procedure TestNotifyListenersOfEstablishedSessionInviteHasNoBody;
    procedure TestOkUsesGruuWhenUaDoes;
    procedure TestInboundModifyBeforeFullyEstablished;
    procedure TestInboundModifyReceivesNoAck;
    procedure TestReceiveBye;
    procedure TestReceiveOutOfOrderReInvite;
    procedure TestRedirectCall;
    procedure TestRejectCallBusy;
    procedure TestRemoveSessionListener;
    procedure TestRing;
    procedure TestRingWithGruu;
    procedure TestSupportsExtension;
    procedure TestTerminate;
    procedure TestTerminateUnestablishedSession;
  end;

  TestTIdSipOutboundSession = class(TestTIdSipSession)
  private
    LocalMimeType:            String;
    LocalDescription:         String;
    OnProgressedSessionFired: Boolean;
    RemoteDesc:               String;
    RemoteMimeType:           String;
    Session:                  TIdSipOutboundSession;

    procedure ReceiveBusyHere(Invite: TIdSipRequest);
    procedure ReceiveForbidden;
    procedure ReceiveMovedTemporarily(Invite: TIdSipRequest;
                                      const Contacts: array of String); overload;
    procedure ReceiveMovedTemporarily(const Contact: String); overload;
    procedure ReceiveMovedTemporarily(const Contacts: array of String); overload;
    procedure ReceiveOKWithRecordRoute;
    procedure ReceiveRemoteDecline;
  protected
    MimeType: String;
    SDP:      String;

    procedure CheckResendWaitTime(Milliseconds: Cardinal;
                                  const Msg: String); override;
    function  CreateAction: TIdSipAction; override;
    procedure EstablishSession(Session: TIdSipSession); override;
    procedure OnEstablishedSession(Session: TIdSipSession;
                                   const RemoteSessionDescription: String;
                                   const MimeType: String); override;
    procedure OnProgressedSession(Session: TIdSipSession;
                                  Progress: TIdSipResponse); override;
  public
    procedure SetUp; override;
  published
    procedure TestAbandonAuthentication; override;
    procedure TestAck;
    procedure TestAckFromRecordRouteResponse;
    procedure TestAckWithAuthorization;
    procedure TestAckWithMultipleAuthorization;
    procedure TestAckWithProxyAuthorization;
    procedure TestCall;
    procedure TestCallNetworkFailure;
    procedure TestCallRemoteRefusal;
    procedure TestCallSecure;
    procedure TestCallSipsUriOverTcp;
    procedure TestCallSipUriOverTls;
    procedure TestCallWithGruu;
    procedure TestCallWithOffer;
    procedure TestCallWithoutOffer;
    procedure TestCancelReceiveInviteOkBeforeCancelOk;
    procedure TestCircularRedirect;
    procedure TestDialogNotEstablishedOnTryingResponse;
    procedure TestDoubleRedirect;
    procedure TestEmptyTargetSetMeansTerminate;
    procedure TestEstablishedSessionSetsInitialRequestToTag;
    procedure TestGlobalFailureEndsSession;
    procedure TestHangUp;
    procedure TestIsOutboundCall;
    procedure TestMethod;
    procedure TestModifyUsesAuthentication;
    procedure TestNetworkFailuresLookLikeSessionFailures;
    procedure TestReceive1xxNotifiesListeners;
    procedure TestReceive2xxSendsAck;
    procedure TestReceive3xxSendsNewInvite;
    procedure TestReceive3xxWithOneContact;
    procedure TestReceive3xxWithNoContacts;
    procedure TestReceiveFailureResponseAfterSessionEstablished;
    procedure TestReceiveFailureResponseNotifiesOnce;
    procedure TestReceiveFailureSetsReason;
    procedure TestReceiveFinalResponseSendsAck;
    procedure TestRedirectAndAccept;
    procedure TestRedirectMultipleOks;
    procedure TestRedirectNoMoreTargets;
    procedure TestRedirectWithMultipleContacts;
    procedure TestRedirectWithNoSuccess;
    procedure TestSendSetsInitialRequest;
    procedure TestSendWithGruu;
    procedure TestSupportsExtension;
    procedure TestTerminateDuringRedirect;
    procedure TestTerminateEstablishedSession;
    procedure TestTerminateNetworkFailure;
    procedure TestTerminateUnestablishedSession;
  end;

  TestSessionReplacer = class(TTestCaseTU,
                              IIdSipInviteModuleListener,
                              IIdSipMessageModuleListener,
                              IIdSipSubscribeModuleListener,
                              IIdSipTransactionUserListener)
  private
    Alice:          TIdSipUserAgent;
    AlicesNewPhone: TIdSipUserAgent;
    Bob:            TIdSipUserAgent;
    InboundCall:    TIdSipInboundSession;
    ParkPlace:      TIdSipUserAgent;
    ReceivingUA:    TIdSipAbstractCore;
    Refer:          TIdSipInboundSubscription;

    function  CreateTransferringUA(Timer: TIdTimerQueue;
                                   const Address: String): TIdSipUserAgent;
    procedure OnDroppedUnmatchedMessage(UserAgent: TIdSipAbstractCore;
                                        Message: TIdSipMessage;
                                        Receiver: TIdSipTransport);
    procedure OnInboundCall(UserAgent: TIdSipInviteModule;
                            Session: TIdSipInboundSession);
    procedure OnRenewedSubscription(UserAgent: TIdSipAbstractCore;
                                    Subscription: TIdSipOutboundSubscription);
    procedure OnSubscriptionRequest(UserAgent: TIdSipAbstractCore;
                                    Subscription: TIdSipInboundSubscription);
    function  SubscribeModuleOf(UA: TIdSipUserAgent): TIdSipSubscribeModule;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSessionReplacer;
  end;

  TestTIdSipInviteModuleOnInboundCallMethod = class(TActionMethodTestCase)
  private
    Invite:   TIdSipRequest;
    Method:   TIdSipInviteModuleInboundCallMethod;
    Listener: TIdSipTestInviteModuleListener;
    Session:  TIdSipInboundSession;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TInviteMethodTestCase = class(TActionMethodTestCase)
  private
    Invite:   TIdSipOutboundInvite;
    Listener: TIdSipTestInviteListener;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TestTIdSipInviteCallProgressMethod = class(TInviteMethodTestCase)
  private
    Method: TIdSipInviteCallProgressMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipInboundInviteFailureMethod = class(TActionMethodTestCase)
  private
    Invite: TIdSipRequest;
    Method: TIdSipInboundInviteFailureMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipInviteDialogEstablishedMethod = class(TActionMethodTestCase)
  private
    Method: TIdSipInviteDialogEstablishedMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestInviteMethod = class(TActionMethodTestCase)
  private
    Invite:   TIdSipOutboundInvite;
    Listener: TIdSipTestInviteListener;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TestTIdSipInviteFailureMethod = class(TestInviteMethod)
  private
    Method: TIdSipInviteFailureMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipInviteRedirectMethod = class(TestInviteMethod)
  private
    Method: TIdSipInviteRedirectMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Run;
  end;

  TestTIdSipInviteSuccessMethod = class(TestInviteMethod)
  private
    Method: TIdSipInviteSuccessMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestSessionMethod = class(TActionMethodTestCase)
  protected
    Listener: TIdSipTestSessionListener;
    Session:  TIdSipSession;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TestTIdSipEndedSessionMethod = class(TestSessionMethod)
  private
    Method: TIdSipEndedSessionMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipEstablishedSessionMethod = class(TestSessionMethod)
  private
    Method: TIdSipEstablishedSessionMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipModifiedSessionMethod = class(TestSessionMethod)
  private
    Answer: TIdSipResponse;
    Method: TIdSipModifiedSessionMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipSessionModifySessionMethod = class(TestSessionMethod)
  private
    Session: TIdSipOutboundSession;
    Method:  TIdSipSessionModifySessionMethod;
  public
    procedure SetUp; override;
  published
    procedure TestRun;
  end;

  TestTIdSipProgressedSessionMethod = class(TestSessionMethod)
  private
    Method:   TIdSipProgressedSessionMethod;
    Progress: TIdSipResponse;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipSessionReferralMethod = class(TestSessionMethod)
  private
    Method: TIdSipSessionReferralMethod;
    Refer:  TIdSipRequest;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

implementation

uses
  IdException, IdSimpleParser, IdSipMockTransactionDispatcher, SysUtils,
  TestFramework;

function Suite: ITestSuite;
begin
  Result := TTestSuite.Create('IdSipInviteModule unit tests');
//  Result.AddTest(TestDebug.Suite);
  Result.AddTest(TestTIdSipInviteModule.Suite);
  Result.AddTest(TestTIdSipInboundInvite.Suite);
{
  Result.AddTest(TestTIdSipOutboundInitialInvite.Suite);
  Result.AddTest(TestTIdSipOutboundRedirectedInvite.Suite);
  Result.AddTest(TestTIdSipOutboundReInvite.Suite);
  Result.AddTest(TestTIdSipOutboundReplacingInvite.Suite);
  Result.AddTest(TestTIdSipInboundSession.Suite);
  Result.AddTest(TestTIdSipOutboundSession.Suite);
  Result.AddTest(TestSessionReplacer.Suite);
  Result.AddTest(TestTIdSipInviteModuleOnInboundCallMethod.Suite);
  Result.AddTest(TestTIdSipInviteCallProgressMethod.Suite);
  Result.AddTest(TestTIdSipInboundInviteFailureMethod.Suite);
  Result.AddTest(TestTIdSipInviteDialogEstablishedMethod.Suite);
  Result.AddTest(TestTIdSipInviteFailureMethod.Suite);
  Result.AddTest(TestTIdSipInviteRedirectMethod.Suite);
  Result.AddTest(TestTIdSipInviteSuccessMethod.Suite);
  Result.AddTest(TestTIdSipEndedSessionMethod.Suite);
  Result.AddTest(TestTIdSipEstablishedSessionMethod.Suite);
  Result.AddTest(TestTIdSipModifiedSessionMethod.Suite);
  Result.AddTest(TestTIdSipSessionModifySessionMethod.Suite);
  Result.AddTest(TestTIdSipProgressedSessionMethod.Suite);
  Result.AddTest(TestTIdSipSessionReferralMethod.Suite);
}  
end;

//******************************************************************************
//* TestDebug                                                                  *
//******************************************************************************
//* TestDebug Private methods **************************************************

procedure TestDebug.OnAuthenticationChallenge(Action: TIdSipAction;
                                              Response: TIdSipResponse);
begin
end;

procedure TestDebug.OnEndedSession(Session: TIdSipSession;
                                   ErrorCode: Cardinal;
                                   const Reason: String);
begin
end;

procedure TestDebug.OnEstablishedSession(Session: TIdSipSession;
                                         const RemoteSessionDescription: String;
                                         const MimeType: String);
begin
end;

procedure TestDebug.OnModifySession(Session: TIdSipSession;
                                    const RemoteSessionDescription: String;
                                    const MimeType: String);
begin
end;

procedure TestDebug.OnModifiedSession(Session: TIdSipSession;
                                      Answer: TIdSipResponse);
begin
end;

procedure TestDebug.OnProgressedSession(Session: TIdSipSession;
                                        Progress: TIdSipResponse);
begin
end;

procedure TestDebug.OnReferral(Session: TIdSipSession;
                               Refer: TIdSipRequest);
begin
end;

procedure TestDebug.OnNetworkFailure(Action: TIdSipAction;
                                     ErrorCode: Cardinal;
                                     const Reason: String);
begin
  Self.FailReason := Reason;
end;

procedure TestDebug.ReceiveMovedTemporarily(Invite: TIdSipRequest;
                                            const Contacts: array of String);
var
  I:        Integer;
  Response: TIdSipResponse;
begin
  Response := TIdSipResponse.InResponseTo(Invite,
                                          SIPMovedTemporarily);
  try
    for I := Low(Contacts) to High(Contacts) do
      Response.AddHeader(ContactHeaderFull).Value := Contacts[I];

    Self.ReceiveResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TestDebug.ReceiveMovedTemporarily(const Contacts: array of String);
begin
  Self.ReceiveMovedTemporarily(Self.LastSentRequest, Contacts);
end;

//* TestDebug Public methods ***************************************************

procedure TestDebug.SetUp;
begin
  inherited SetUp;

  Self.Session := Self.Core.InviteModule.Call(Self.Destination, '', '');
  Self.Session.AddSessionListener(Self);
  Self.Session.Send;

  // DNS entries for redirected domains, etc.
  Self.Locator.AddA('bar.org',   '127.0.0.1');
  Self.Locator.AddA('quaax.org', '127.0.0.1');
end;

//* TestDebug Published methods ************************************************

procedure TestDebug.TestSendSetsInitialRequest;
var
  Session: TIdSipOutboundSession;
begin
  Session := Core.InviteModule.Call(Self.Destination, '', '') as TIdSipOutboundSession;
  Session.AddSessionListener(Self);
  Session.Send;

  Check(Session.InitialRequest.Equals(Self.LastSentRequest),
        'Sending the session didn''t set the session''s InitialRequest');
end;

procedure TestDebug.TestTerminateDuringRedirect;
var
  Contacts: array of String;
  I:        Integer;
begin
  //                             Request count
  //  ---       INVITE      ---> #0
  // <---   302 (foo,bar)   ---
  //  ---        ACK        --->
  //  ---    INVITE (foo)   ---> #1
  //  ---    INVITE (bar)   ---> #2
  // <---     100 (foo)     --- (we receive 100s so the InviteActions will send CANCELs immediately)
  // <---     100 (bar)     ---
  // <Terminate the connection attempt>
  //  ---    CANCEL (foo)   ---> #3
  // <--- 200 (foo, CANCEL) ---
  //  ---    CANCEL (bar)   ---> #4
  // <--- 200 (bar, CANCEL) ---

  SetLength(Contacts, 2);
  Contacts[0] := 'sip:foo@bar.org';
  Contacts[1] := 'sip:bar@bar.org';

  Self.ReceiveMovedTemporarily(Contacts);

  Check(Self.SentRequestCount >= 3,
        'Not enough requests sent: 1 + 2 INVITEs: ' + Self.FailReason);

  Self.ReceiveTrying(Self.SentRequestAt(1));
  Self.ReceiveTrying(Self.SentRequestAt(2));

  Self.MarkSentRequestCount;
  Self.Session.Terminate;

  // ARG! Why do they make Length return an INTEGER? And WHY Abs() too?
  CheckEquals(Self.RequestCount + Cardinal(Length(Contacts)),
              Self.Dispatcher.Transport.SentRequestCount,
              'Session didn''t attempt to terminate all INVITEs');

  Check(Self.SentRequestCount >= 5,
        'Not enough requests sent: 1 + 2 INVITEs, 2 CANCELs');

  for I := 0 to 1 do begin
    CheckEquals(Contacts[I],
                Self.SentRequestAt(I + 3).RequestUri.Uri,
                'CANCEL to ' + Contacts[I]);
    CheckEquals(MethodCancel,
                Self.SentRequestAt(I + 3).Method,
                'Request method to ' + Contacts[I]);
  end;
end;

//******************************************************************************
//* TestTIdSipInviteModule                                                     *
//******************************************************************************
//* TestTIdSipInviteModule Public **********************************************

procedure TestTIdSipInviteModule.SetUp;
var
  Invite:   TIdSipRequest;
  Response: TIdSipResponse;
begin
  inherited SetUp;

  Self.Module := Self.Core.ModuleFor(MethodInvite) as TIdSipInviteModule;

  Invite := TIdSipTestResources.CreateBasicRequest;
  try
    Response := TIdSipTestResources.CreateBasicResponse;
    try
      Self.Dlg := TIdSipDialog.CreateInboundDialog(Invite,
                                                   Response,
                                                   false);
      Self.Dlg.ReceiveRequest(Invite);
      Self.Dlg.ReceiveResponse(Response)
    finally
      Response.Free;
    end;
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipInviteModule.CheckCommaSeparatedHeaders(const ExpectedValues: String;
                                                            Header: TIdSipHeader;
                                                            const Msg: String);
var
  Hdr:    TIdSipCommaSeparatedHeader;
  I:      Integer;
  Values: TStringList;
begin
  CheckEquals(TIdSipCommaSeparatedHeader.ClassName,
              Header.ClassName,
              Msg + ': Unexpected header type in CheckCommaSeparatedHeaders');

  Hdr := Header as TIdSipCommaSeparatedHeader;
  Values := TStringList.Create;
  try
    Values.CommaText := ExpectedValues;

    for I := 0 to Values.Count - 1 do
      CheckEquals(Values[I],
                  Hdr.Values[I],
                  Msg + ': ' + IntToStr(I + 1) + 'th value');
  finally
    Values.Free;
  end;
end;

procedure TestTIdSipInviteModule.CheckCreateRequest(Dest: TIdSipToHeader;
                                                    Request: TIdSipRequest);
var
  Contact: TIdSipContactHeader;
begin
  CheckEquals(Dest.Address,
              Request.RequestUri,
              'Request-URI not properly set');

  Check(Request.HasHeader(CallIDHeaderFull), 'No Call-ID header added');
  CheckNotEquals('',
                 (Request.FirstHeader(CallIDHeaderFull) as TIdSipCallIdHeader).Value,
                 'Call-ID must not be empty');

  Check(Request.HasHeader(ContactHeaderFull), 'No Contact header added');
  Contact := Request.FirstContact;
  Check(Contact.Equals(Self.Core.Contact), 'Contact header incorrectly set');

  CheckEquals(Request.From.DisplayName,
              Self.Core.From.DisplayName,
              'From.DisplayName');
  CheckEquals(Request.From.Address,
              Self.Core.From.Address,
              'From.Address');
    Check(Request.From.HasTag,
          'Requests MUST have a From tag; cf. RFC 3261 section 8.1.1.3');

  CheckEquals(Request.RequestUri,
              Request.ToHeader.Address,
              'To header incorrectly set');

  CheckEquals(1,
              Request.Path.Length,
              'New requests MUST have a Via header; cf. RFC 3261 section 8.1.1.7');
  Check(Request.LastHop.HasBranch,
        'New requests MUST have a branch; cf. RFC 3261 section 8.1.1.7');
  CheckEquals(UdpTransport,
              Request.LastHop.Transport,
              'UDP should be the default transport');
end;

function TestTIdSipInviteModule.ConvertListToHeader(List: TStrings): String;
begin
  Result := StringReplace(List.CommaText, ',', ', ', [rfReplaceAll]);
end;

//* TestTIdSipInviteModule Published *******************************************

procedure TestTIdSipInviteModule.TestAddListener;
var
  L1, L2: TIdSipTestInviteModuleListener;
begin
  L1 := TIdSipTestInviteModuleListener.Create;
  try
    L2 := TIdSipTestInviteModuleListener.Create;
    try
      Self.Module.AddListener(L1);
      Self.Module.AddListener(L2);

      Self.ReceiveInvite;

      Check(L1.InboundCall, 'First listener not notified of inbound call');
      Check(L2.InboundCall, 'Second listener not notified of inbound call');
    finally
      L2.Free;
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestCreateAck;
var
  Ack: TIdSipRequest;
begin
  Ack := Self.Module.CreateAck(Self.Dlg);
  try
    CheckEquals(1, Ack.Path.Count, 'Wrong number of Via headers');
  finally
    Ack.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestCreateBye;
var
  Bye: TIdSipRequest;
begin
  Bye := Self.Module.CreateBye(Self.Dlg);
  try
    CheckEquals(MethodBye, Bye.Method, 'Unexpected method');
    CheckEquals(Bye.Method,
                Bye.CSeq.Method,
                'CSeq method doesn''t match request method');
  finally
    Bye.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestCreateInvite;
var
  Dest:    TIdSipToHeader;
  Request: TIdSipRequest;
begin
  Dest := TIdSipToHeader.Create;
  try
    Dest.Address.URI := 'sip:wintermute@tessier-ashpool.co.luna';
    Request := Self.Module.CreateInvite(Dest, '', '');
    try
      Self.CheckCreateRequest(Dest, Request);
      CheckEquals(MethodInvite, Request.Method, 'Incorrect method');

      Check(not Request.ToHeader.HasTag,
            'This request is outside of a dialog, hence MUST NOT have a '
          + 'To tag. See RFC:3261, section 8.1.1.2');

      Check(Request.HasHeader(CSeqHeader), 'No CSeq header');
      Check(not Request.HasHeader(ContentDispositionHeader),
            'Needless Content-Disposition header');

      Check(Request.HasHeader(AllowHeader), 'No Allow header');
      CheckCommaSeparatedHeaders(Self.Core.KnownMethods,
                                 Request.FirstHeader(AllowHeader),
                                 'Allow header');

      Check(Request.HasHeader(SupportedHeaderFull), 'No Supported header');
      CheckEquals(Self.Core.AllowedExtensions,
                  Request.FirstHeader(SupportedHeaderFull).Value,
                  'Supported header value');
    finally
      Request.Free;
    end;
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestCreateInviteInsideDialog;
var
  Invite: TIdSipRequest;
begin
  Invite := Self.Module.CreateReInvite(Self.Dlg, '', '');
  try
      Check(Invite.ToHeader.HasTag,
            'This request is inside a dialog, hence MUST have a '
          + 'To tag. See RFC:3261, section 12.2.1.1');
      CheckEquals(Self.Dlg.ID.RemoteTag,
                  Invite.ToHeader.Tag,
                  'To tag');

      Check(Invite.HasHeader(CSeqHeader), 'No CSeq header');
      Check(not Invite.HasHeader(ContentDispositionHeader),
            'Needless Content-Disposition header');

    Check(Invite.HasHeader(AllowHeader), 'No Allow header');
    CheckCommaSeparatedHeaders(Self.Core.KnownMethods,
                               Invite.FirstHeader(AllowHeader),
                               'Allow header');

    Check(Invite.HasHeader(SupportedHeaderFull), 'No Supported header');
    CheckEquals(Self.Core.AllowedExtensions,
                Invite.FirstHeader(SupportedHeaderFull).Value,
                'Supported header value');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestCreateInviteWithBody;
var
  Invite: TIdSipRequest;
  Body:   String;
begin
  Body := 'foo fighters';

  Invite := Self.Module.CreateInvite(Self.Destination, Body, 'text/plain');
  try
    CheckEquals(Length(Body), Invite.ContentLength, 'Content-Length');
    CheckEquals(Body,         Invite.Body,          'Body');

    Check(Invite.HasHeader(ContentDispositionHeader),
          'Missing Content-Disposition');
    CheckEquals(DispositionSession,
                Invite.ContentDisposition.Value,
                'Content-Disposition value');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestCreateInviteWithGruu;
var
  Invite: TIdSipRequest;
begin
  Self.UseGruu;

  Invite := Self.Module.CreateInvite(Self.Destination, '', '');
  try
    Check(not Invite.FirstContact.Address.HasGrid,
          '"grid" parameter automatically added to Contact');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestCreateReInvite;
var
  Invite: TIdSipRequest;
begin
  Invite := Self.Module.CreateReInvite(Self.Dlg, 'foo', 'bar');
  try
    CheckEquals(MethodInvite, Invite.Method, 'Method');
    CheckEquals('foo',        Invite.Body, 'Body');
    CheckEquals('bar',        Invite.ContentType, 'Content-Type');

    CheckEquals(Self.Dlg.ID.CallID,
                Invite.CallID,
                'Call-ID');
    CheckEquals(Self.Dlg.ID.LocalTag,
                Invite.From.Tag,
                'From tag');
    CheckEquals(Self.Dlg.ID.RemoteTag,
                Invite.ToHeader.Tag,
                'To tag');
    CheckEquals(Self.Dlg.LocalSequenceNo,
                Invite.CSeq.SequenceNo,
                'CSeq sequence no');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestDoNotDisturb;
var
  SessionCount: Cardinal;
begin
  Self.Core.DoNotDisturb := true;
  Self.MarkSentResponseCount;
  SessionCount  := Self.Core.SessionCount;

  Self.ReceiveInvite;
  CheckResponseSent('No response sent when UA set to Do Not Disturb');

  CheckEquals(SIPTemporarilyUnavailable,
              Self.LastSentResponse.StatusCode,
              'Wrong response sent');
  CheckEquals(Self.Core.DoNotDisturbMessage,
              Self.LastSentResponse.StatusText,
              'Wrong status text');
  CheckEquals(SessionCount,
              Self.Core.SessionCount,
              'New session created despite Do Not Disturb');
end;

procedure TestTIdSipInviteModule.TestReceiveByeForUnmatchedDialog;
var
  Bye:      TIdSipRequest;
  Response: TIdSipResponse;
begin
  Bye := Self.Core.CreateRequest(MethodInvite, Self.Destination);
  try
    Bye.Method          := MethodBye;
    Bye.CSeq.SequenceNo := $deadbeef;
    Bye.CSeq.Method     := Bye.Method;

    Self.MarkSentResponseCount;

    Self.ReceiveRequest(Bye);

    CheckResponseSent('No response sent');
    Response := Self.LastSentResponse;
    CheckEquals(SIPCallLegOrTransactionDoesNotExist,
                Response.StatusCode,
                'Response Status-Code')

  finally
    Bye.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestReceiveByeWithoutTags;
var
  Bye:      TIdSipRequest;
  Response: TIdSipResponse;
begin
  Bye := Self.Core.CreateRequest(MethodInvite, Self.Destination);
  try
    Bye.Method          := MethodBye;
    Bye.From.Value      := Bye.From.Address.URI;     // strip the tag
    Bye.ToHeader.Value  := Bye.ToHeader.Address.URI; // strip the tag
    Bye.CSeq.SequenceNo := $deadbeef;
    Bye.CSeq.Method     := Bye.Method;

    Self.MarkSentResponseCount;

    Self.ReceiveRequest(Bye);

    CheckResponseSent('No response sent');
    Response := Self.LastSentResponse;
    CheckEquals(SIPCallLegOrTransactionDoesNotExist,
                Response.StatusCode,
                'Response Status-Code')
  finally
    Bye.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestReceiveInviteWithMultipleReplacesHeaders;
var
  BadRequest: TIdSipRequest;
begin
  BadRequest := Self.Invite.Copy as TIdSipRequest;
  try
    BadRequest.AddHeader(SupportedHeaderFull).Value := ExtensionReplaces;
    BadRequest.AddHeader(ReplacesHeader).Value := '1;from-tag=2;to-tag=3';
    BadRequest.AddHeader(ReplacesHeader).Value := '2;from-tag=3;to-tag=4';

    Self.MarkSentResponseCount;
    Self.ReceiveRequest(BadRequest);

    CheckResponseSent('No response sent');
    CheckEquals(SIPBadRequest,
                Self.LastSentResponse.StatusCode,
                'Unexpected response');
  finally
    BadRequest.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestReceiveInviteWithNoContactHeader;
var
  BadRequest: TIdSipRequest;
begin
  BadRequest := Self.Invite.Copy as TIdSipRequest;
  try
    BadRequest.RemoveAllHeadersNamed(ContactHeaderFull);

    Self.MarkSentResponseCount;
    Self.ReceiveRequest(BadRequest);

    CheckResponseSent('No response sent');
    CheckEquals(SIPBadRequest,
                Self.LastSentResponse.StatusCode,
                'Unexpected response');
    CheckEquals(MissingContactHeader,
                Self.LastSentResponse.StatusText,
                'Unexpected response Status-Text');
  finally
    BadRequest.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestRejectUnknownContentType;
var
  Response: TIdSipResponse;
begin
  Self.MarkSentResponseCount;

  Self.Invite.ContentType := 'text/xml';

  Self.ReceiveInvite;

  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPUnsupportedMediaType, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(AcceptHeader), 'No Accept header');
  CheckEquals(Self.ConvertListToHeader(Self.Module.AllowedContentTypes),
              Response.FirstHeader(AcceptHeader).Value,
              'Accept value');
end;

procedure TestTIdSipInviteModule.TestRemoveListener;
var
  Listener: TIdSipTestInviteModuleListener;
begin
  Listener := TIdSipTestInviteModuleListener.Create;
  try
    Self.Module.AddListener(Listener);
    Self.Module.RemoveListener(Listener);

    Self.ReceiveInvite;

    Check(not Listener.InboundCall,
          'First listener notified of inbound call, ergo not removed');
  finally
    Listener.Free;
  end;
end;

procedure TestTIdSipInviteModule.TestReplaceCall;
var
  Session: TIdSipOutboundSession;
begin
  Session := Self.Module.ReplaceCall(Self.Invite, Self.Destination, '', '');

  Self.MarkSentRequestCount;
  Session.Send;
  CheckRequestSent('No request sent');
  Check(Self.LastSentRequest.HasHeader(ReplacesHeader),
        'No Replaces header, hence the session''s not a dialog replacer');
end;

//******************************************************************************
//* TestTIdSipInboundInvite                                                    *
//******************************************************************************
//* TestTIdSipInboundInvite Public methods *************************************

procedure TestTIdSipInboundInvite.SetUp;
var
  Ok: TIdSipResponse;
begin
  inherited SetUp;

  Self.Module := Self.Core.ModuleFor(MethodInvite) as TIdSipInviteModule;

  Ok := TIdSipResponse.InResponseTo(Self.Invite, SIPOK);
  try
    Ok.ToHeader.Tag := Self.Core.NextTag;
    Self.Dialog := TIdSipDialog.CreateInboundDialog(Self.Invite, Ok, true);
  finally
    Ok.Free;
  end;

  Self.Answer         := '';
  Self.Failed         := false;
  Self.OnSuccessFired := false;

  Self.InviteAction := TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false);
  Self.InviteAction.AddListener(Self);
end;

procedure TestTIdSipInboundInvite.TearDown;
begin
  Self.InviteAction.Free;
  Self.Dialog.Free;

  inherited TearDown;
end;

//* TestTIdSipInboundInvite Private methods ************************************

procedure TestTIdSipInboundInvite.CheckAck(InviteAction: TIdSipInboundInvite);
var
  Ack:          TIdSipRequest;
  RemoteDialog: TIdSipDialog;
begin
  InviteAction.Accept('', '');

  RemoteDialog := TIdSipDialog.CreateOutboundDialog(InviteAction.InitialRequest,
                                                    Self.LastSentResponse,
                                                    false);
  try
    RemoteDialog.ReceiveRequest(InviteAction.InitialRequest);
    RemoteDialog.ReceiveResponse(Self.LastSentResponse);

    Ack := Self.Module.CreateAck(RemoteDialog);
    try
      Check(InviteAction.Match(Ack),
            'ACK must match the InviteAction');
    finally
      Ack.Free;
    end;
  finally
    RemoteDialog.Free;
  end;
end;

procedure TestTIdSipInboundInvite.CheckAckWithDifferentCSeq(InviteAction: TIdSipInboundInvite);
var
  Ack:          TIdSipRequest;
  RemoteDialog: TIdSipDialog;
begin
  InviteAction.Accept('', '');

  RemoteDialog := TIdSipDialog.CreateOutboundDialog(InviteAction.InitialRequest,
                                                    Self.LastSentResponse,
                                                    false);
  try
    RemoteDialog.ReceiveRequest(InviteAction.InitialRequest);
    RemoteDialog.ReceiveResponse(Self.LastSentResponse);

    Ack := Self.Module.CreateAck(RemoteDialog);
    try
      Ack.CSeq.Increment;
      Check(not InviteAction.Match(Ack),
            'ACK must not match the InviteAction');
    finally
      Ack.Free;
    end;
  finally
    RemoteDialog.Free;
  end;
end;

procedure TestTIdSipInboundInvite.OnFailure(InviteAgent: TIdSipInboundInvite);
begin
  Self.Failed := true;
end;

procedure TestTIdSipInboundInvite.OnSuccess(InviteAgent: TIdSipInboundInvite;
                                            Ack: TIdSipRequest);
begin
  Self.Answer         := Ack.Body;
  Self.AnswerMimeType := Ack.ContentType;
  Self.OnSuccessFired := true;
end;

//* TestTIdSipInboundInvite Published methods **********************************

procedure TestTIdSipInboundInvite.TestAccept;
var
  Body:        String;
  ContentType: String;
  Response:    TIdSipResponse;
begin
  Self.MarkSentResponseCount;

  Body        := 'foo';
  ContentType := 'bar';
  Self.InviteAction.Accept(Body, ContentType);

  CheckResponseSent('No response sent');
  Response := Self.LastSentResponse;
  CheckEquals(SIPOK,
              Response.StatusCode,
              'Unexpected Status-Code');

  Check(Response.From.HasTag,                  'No From tag');
  Check(Response.ToHeader.HasTag,              'No To tag');
  Check(Response.HasHeader(ContactHeaderFull), 'No Contact header');

  Check(Response.ToHeader.HasTag,
        'To (local) tag missing');
  CheckEquals(Body,
              Response.Body,
              'Body');
  CheckEquals(ContentType,
              Response.ContentType,
              'Content-Type');
end;

procedure TestTIdSipInboundInvite.TestCancelAfterAccept;
var
  Cancel:         TIdSipRequest;
  CancelResponse: TIdSipResponse;
  InviteResponse: TIdSipResponse;
begin
  // <--- INVITE ---
  //  --- 200 OK --->
  // <---  ACK   ---
  // <--- CANCEL ---
  //  --- 200 OK --->

  Self.InviteAction.Accept('', '');

  Self.MarkSentResponseCount;
  Cancel := Self.Invite.CreateCancel;
  try
    Self.InviteAction.ReceiveRequest(Cancel);
  finally
    Cancel.Free;
  end;

  Check(not Self.InviteAction.IsTerminated,
        'Action terminated');
  Check(not Self.Failed,
        'Listeners notified of (false) failure');

  CheckResponseSent('No response sent');

  CancelResponse := Self.LastSentResponse;
  InviteResponse := Self.Dispatcher.Transport.SecondLastResponse;

  CheckEquals(SIPOK,
              CancelResponse.StatusCode,
              'Unexpected Status-Code for CANCEL response');
  CheckEquals(MethodCancel,
              CancelResponse.CSeq.Method,
              'Unexpected CSeq method for CANCEL response');

  CheckEquals(SIPOK,
              InviteResponse.StatusCode,
              'Unexpected Status-Code for INVITE response');
  CheckEquals(MethodInvite,
              InviteResponse.CSeq.Method,
              'Unexpected CSeq method for INVITE response');
end;

procedure TestTIdSipInboundInvite.TestCancelBeforeAccept;
var
  Cancel: TIdSipRequest;
begin
  // <---         INVITE         ---
  // <---         CANCEL         ---
  //  ---         200 OK         ---> (for the CANCEL)
  //  --- 487 Request Terminated ---> (for the INVITE)
  // <---           ACK          ---

  Cancel := Self.Invite.CreateCancel;
  try
    Self.InviteAction.ReceiveRequest(Cancel);
  finally
    Cancel.Free;
  end;

  Check(Self.InviteAction.IsTerminated,
        'Action not marked as terminated');
  Check(Self.Failed,
        'Listeners not notified of failure');
end;

procedure TestTIdSipInboundInvite.TestInviteWithNoOffer;
var
  Ack:    TIdSipRequest;
  Action: TIdSipInboundInvite;
  Answer: String;
  Offer:  String;
begin
  // <---       INVITE        ---
  //  --- 200 OK (with offer) --->
  // <---  ACK (with answer)  ---

  Answer := TIdSipTestResources.BasicSDP('4.3.2.1');
  Offer  := TIdSipTestResources.BasicSDP('1.2.3.4');

  Self.Invite.Body := '';
  Self.Invite.RemoveAllHeadersNamed(ContentTypeHeaderFull);

  Action := TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false);
  Action.AddListener(Self);

  Self.MarkSentResponseCount;
  Action.Accept(Offer,
                SdpMimeType);

  Self.CheckResponseSent('No 2xx sent');
  CheckEquals(Offer,
              Self.LastSentResponse.Body,
              'Body of 2xx');
  CheckEquals(SdpMimeType,
              Self.LastSentResponse.ContentType,
              'Content-Type of 2xx');

  Ack := Self.Invite.AckFor(Self.LastSentResponse);
  try
    Ack.Body                        := Answer;
    Ack.ContentDisposition.Handling := DispositionSession;
    Ack.ContentLength               := Length(Answer);
    Ack.ContentType                 := Self.LastSentResponse.ContentType;

    Action.ReceiveRequest(Ack);
  finally
    Ack.Free;
  end;

  Check(Self.OnSuccessFired,
        'InviteAction never received the ACK');

  CheckEquals(Answer,
              Self.Answer,
              'ACK''s body');
  CheckEquals(Self.LastSentResponse.ContentType,
              Self.AnswerMimeType,
              'ACK''s Content-Type');
end;

procedure TestTIdSipInboundInvite.TestIsInbound;
begin
  Check(Self.InviteAction.IsInbound,
        Self.InviteAction.ClassName + ' not marked as inbound');
end;

procedure TestTIdSipInboundInvite.TestIsInvite;
begin
  Check(Self.InviteAction.IsInvite,
        Self.InviteAction.ClassName + ' not marked as a Invite');
end;

procedure TestTIdSipInboundInvite.TestIsOptions;
begin
  Check(not Self.InviteAction.IsOptions,
        Self.InviteAction.ClassName + ' marked as an Options');
end;

procedure TestTIdSipInboundInvite.TestIsRegistration;
begin
  Check(not Self.InviteAction.IsRegistration,
        Self.InviteAction.ClassName + ' marked as a Registration');
end;

procedure TestTIdSipInboundInvite.TestIsSession;
begin
  Check(not Self.InviteAction.IsSession,
        Self.InviteAction.ClassName + ' marked as a Session');
end;

procedure TestTIdSipInboundInvite.TestLastResponse;
begin
  Self.InviteAction.Ring;
  Check(Self.InviteAction.LastResponse.Equals(Self.LastSentResponse),
        'Sent 180 Ringing not stored in LastResponse');

  Self.InviteAction.Accept('', '');
  Check(Self.InviteAction.LastResponse.Equals(Self.LastSentResponse),
        'Sent 200 OK not stored in LastResponse');

  Self.InviteAction.ResendOk;
  Check(Self.InviteAction.LastResponse.Equals(Self.LastSentResponse),
        'Re-sent 200 OK not stored in LastResponse');
end;

procedure TestTIdSipInboundInvite.TestLocalGruu;
begin
  Self.UseGruu;

  Self.MarkSentResponseCount;
  Self.InviteAction.Accept('', '');
  CheckResponseSent('No 200 OK sent');

  Check(Self.LastSentResponse.FirstContact.Address.HasGrid,
        '200 OK''s Contact address has no "grid" parameter');
  CheckEquals(Self.LastSentResponse.FirstContact.AsString,
              Self.InviteAction.LocalGruu.AsString,
              'InviteAction''s LocalGruu doesn''t match Contact in 200 OK');
end;

procedure TestTIdSipInboundInvite.TestMatchAck;
begin
  Self.InviteAction.Accept('', '');

  Self.CheckAck(Self.InviteAction);
end;

procedure TestTIdSipInboundInvite.TestMatchAckToReInvite;
var
  Action: TIdSipInboundInvite;
begin
  // We want an in-dialog action
  Self.Invite.ToHeader.Tag := Self.Core.NextTag;

  Action := TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false);
  try
    Action.Accept('', '');

    Self.CheckAck(Action);
  finally
    Action.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestMatchAckToReInviteWithDifferentCSeq;
var
  Action: TIdSipInboundInvite;
begin
  // We want an in-dialog action
  Self.Invite.ToHeader.Tag := Self.Core.NextTag;

  Action := TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false);
  try
    Self.CheckAckWithDifferentCSeq(Action);
  finally
    Action.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestMatchAckWithDifferentCSeq;
begin
  Self.CheckAckWithDifferentCSeq(Self.InviteAction);
end;

procedure TestTIdSipInboundInvite.TestMethod;
begin
  CheckEquals(MethodInvite,
              TIdSipInboundInvite.Method,
              'Inbound INVITE Method');
end;

procedure TestTIdSipInboundInvite.TestNotifyOfNetworkFailure;
var
  L1, L2: TIdSipTestInboundInviteListener;
begin
  L1 := TIdSipTestInboundInviteListener.Create;
  try
    L2 := TIdSipTestInboundInviteListener.Create;
    try
      Self.InviteAction.AddListener(L1);
      Self.InviteAction.AddListener(L2);

      Self.Dispatcher.Transport.FailWith := EIdConnectTimeout;

      Self.InviteAction.Accept('', '');

      Check(Self.InviteAction.IsTerminated, 'Action not marked as terminated');
      Check(L1.NetworkFailed, 'L1 not notified');
      Check(L2.NetworkFailed, 'L2 not notified');
    finally
       Self.InviteAction.RemoveListener(L2);
       L2.Free;
    end;
  finally
     Self.InviteAction.RemoveListener(L1);
    L1.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestNotifyOfSuccess;
var
  Ack:    TIdSipRequest;
  L1, L2: TIdSipTestInboundInviteListener;
begin
  L1 := TIdSipTestInboundInviteListener.Create;
  try
    L2 := TIdSipTestInboundInviteListener.Create;
    try
      Self.InviteAction.AddListener(L1);
      Self.InviteAction.AddListener(L2);

      Self.InviteAction.Accept('', '');

      Ack := Self.InviteAction.InitialRequest.AckFor(Self.LastSentResponse);
      try
        Self.InviteAction.ReceiveRequest(Ack);
      finally
        Ack.Free;
      end;

      Check(L1.Succeeded, 'L1 not notified of action success');
      Check(L2.Succeeded, 'L2 not notified of action success');
    finally
       Self.InviteAction.RemoveListener(L2);
       L2.Free;
    end;
  finally
     Self.InviteAction.RemoveListener(L1);
    L1.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestReceiveResentAck;
var
  Ack:      TIdSipRequest;
  Listener: TIdSipTestInboundInviteListener;
begin
  Self.InviteAction.Accept('', '');

  Ack := Self.InviteAction.InitialRequest.AckFor(Self.LastSentResponse);
  try
    Self.InviteAction.ReceiveRequest(Ack);

    Listener := TIdSipTestInboundInviteListener.Create;
    try
      Self.InviteAction.AddListener(Listener);

      Self.InviteAction.ReceiveRequest(Ack);
      Check(not Listener.Succeeded, 'The InboundInvite renotified its listeners of success');
    finally
      Listener.Free;
    end;
  finally
    Ack.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestRedirectCall;
var
  Dest:         TIdSipAddressHeader;
  SentResponse: TIdSipResponse;
begin
  Self.MarkSentResponseCount;

  Dest := TIdSipAddressHeader.Create;
  try
    Dest.DisplayName := 'Wintermute';
    Dest.Address.Uri := 'sip:wintermute@talking-head.tessier-ashpool.co.luna';

    Self.InviteAction.Redirect(Dest);
    CheckResponseSent('No response sent');

    SentResponse := Self.LastSentResponse;
    CheckEquals(SIPMovedTemporarily,
                SentResponse.StatusCode,
                'Wrong response sent');
    Check(SentResponse.HasHeader(ContactHeaderFull),
          'No Contact header');
    CheckEquals(Dest.DisplayName,
                SentResponse.FirstContact.DisplayName,
                'Contact display name');
    CheckEquals(Dest.Address.Uri,
                SentResponse.FirstContact.Address.Uri,
                'Contact address');

    Check(Self.InviteAction.IsTerminated,
          'Action didn''t terminate');
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestRedirectCallPermanent;
var
  Dest:         TIdSipAddressHeader;
  SentResponse: TIdSipResponse;
begin
  Self.MarkSentResponseCount;

  Dest := TIdSipAddressHeader.Create;
  try
    Dest.DisplayName := 'Wintermute';
    Dest.Address.Uri := 'sip:wintermute@talking-head.tessier-ashpool.co.luna';

    Self.InviteAction.Redirect(Dest, false);
    CheckResponseSent('No response sent');

    SentResponse := Self.LastSentResponse;
    CheckEquals(SIPMovedPermanently,
                SentResponse.StatusCode,
                'Wrong response sent');
    Check(SentResponse.HasHeader(ContactHeaderFull),
          'No Contact header');
    CheckEquals(Dest.DisplayName,
                SentResponse.FirstContact.DisplayName,
                'Contact display name');
    CheckEquals(Dest.Address.Uri,
                SentResponse.FirstContact.Address.Uri,
                'Contact address');

    Check(Self.InviteAction.IsTerminated,
          'Action didn''t terminate');
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestRejectCallBusy;
var
  Response: TIdSipResponse;
begin
  Self.MarkSentResponseCount;
  Self.InviteAction.RejectCallBusy;
  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPBusyHere,
              Response.StatusCode,
              'Unexpected Status-Code');
  Check(Self.InviteAction.IsTerminated,
        'Action not terminated');
end;

procedure TestTIdSipInboundInvite.TestResendOk;
var
  Ack:        TIdSipRequest;
  I:          Integer;
  OriginalOk: TIdSipResponse;
begin
  Self.InviteAction.Accept('', '');

  // We make sure that repeated calls to ResendOk, well, resend the OK.
  OriginalOk := TIdSipResponse.Create;
  try
    OriginalOk.Assign(Self.LastSentResponse);

    for I := 1 to 2 do begin
      Self.MarkSentResponseCount;
      Self.InviteAction.ResendOk;

      CheckResponseSent(IntToStr(I) + ': Response not resent');
      CheckEquals(SIPOK,
                  Self.LastSentResponse.StatusCode,
                  IntToStr(I) + ': Unexpected response code');
      Check(OriginalOk.Equals(Self.LastSentResponse),
            IntToStr(I) + ': Unexpected OK');
    end;
  finally
    OriginalOk.Free;
  end;

  // But once we receive an ACK, we don't want to resend the OK.
  Ack := Self.Invite.AckFor(Self.LastSentResponse);
  try
    Self.InviteAction.ReceiveRequest(Ack);
  finally
    Ack.Free;
  end;

  Self.MarkSentResponseCount;
  Self.InviteAction.ResendOk;
  CheckNoResponseSent('The action sent an OK after it received an ACK');
end;

procedure TestTIdSipInboundInvite.TestRing;
var
  Response: TIdSipResponse;
begin
  Self.MarkSentResponseCount;
  Self.InviteAction.Ring;

  CheckResponseSent('No ringing response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPRinging,
              Response.StatusCode,
              'Unexpected Status-Code');
  Check(Response.ToHeader.HasTag,
        'To header doesn''t have tag');
  Check(Response.ToHeader.HasTag,
        'To (local) tag');
end;

procedure TestTIdSipInboundInvite.TestRingWithGruu;
var
  Action:   TIdSipInboundInvite;
  Response: TIdSipResponse;
begin
  Self.UseGruu;

  Action := TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false);
  try
    Self.MarkSentResponseCount;
    Action.Ring;

    CheckResponseSent('No ringing response sent');

    Response := Self.LastSentResponse;
    Check(Response.HasHeader(SupportedHeaderFull),
          'Response lacks a Supported header');
    Check(Response.SupportsExtension(ExtensionGruu),
          'Supported header lacks indication of GRUU support');
    Check(Response.FirstContact.Address.HasGrid,
          '180 Ringing lacks a Contact with a "grid" parameter');
  finally
    Action.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestSendSessionProgress;
begin
  Self.MarkSentResponseCount;
  Self.InviteAction.SendSessionProgress;

  CheckResponseSent('No session progress response sent');

  CheckEquals(SIPSessionProgress,
              Self.LastSentResponse.StatusCode,
              'Unexpected Status-Code');
end;

procedure TestTIdSipInboundInvite.TestSendSessionProgressWithGruu;
var
  Action:   TIdSipInboundInvite;
  Response: TIdSipResponse;
begin
  Self.UseGruu;

  Action := TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false);
  try
    Self.MarkSentResponseCount;
    Action.Ring;
    Action.SendSessionProgress;

    CheckResponseSent('No session progress response sent');

    Response := Self.LastSentResponse;
    Check(Response.HasHeader(SupportedHeaderFull),
          'Response lacks a Supported header');
    Check(Response.SupportsExtension(ExtensionGruu),
          'Supported header lacks indication of GRUU support');
    Check(Response.FirstContact.Address.HasGrid,
          '183 Session Progress lacks a Contact with a "grid" parameter');
  finally
    Action.Free;
  end;
end;

procedure TestTIdSipInboundInvite.TestTerminateAfterAccept;
begin
  // This should never happen, really. If you accept a call then InviteAction
  // terminates. Thus by calling Terminate you try to terminate an
  // already-terminated action - which should do nothing. In fact, the UA should
  // have already destroyed the action.

  Self.InviteAction.Accept('', '');

  Self.MarkSentResponseCount;
  Self.InviteAction.Terminate;

  CheckNoResponseSent('Response sent');
  Check(Self.InviteAction.IsTerminated,
        'Action not marked as terminated');
end;

procedure TestTIdSipInboundInvite.TestTerminateBeforeAccept;
begin
  Self.MarkSentResponseCount;

  Self.InviteAction.Terminate;

  CheckResponseSent(Self.ClassName + ': No response sent');

  CheckEquals(SIPRequestTerminated,
              Self.LastSentResponse.StatusCode,
              Self.ClassName + ': Unexpected Status-Code');

  Check(Self.InviteAction.IsTerminated,
        Self.ClassName + ': Action not marked as terminated');
end;

procedure TestTIdSipInboundInvite.TestTimeOut;
begin
  Self.MarkSentResponseCount;

  Self.InviteAction.TimeOut;

  CheckResponseSent('No response sent');

  CheckEquals(SIPRequestTerminated,
              Self.LastSentResponse.StatusCode,
              'Unexpected Status-Code');

  Check(Self.InviteAction.IsTerminated,
        'Action not marked as terminated');
  Check(Self.Failed,
        'Listeners not notified of failure');
end;

//******************************************************************************
//* TestTIdSipOutboundInvite                                                   *
//******************************************************************************
//* TestTIdSipOutboundInvite Public methods ************************************

procedure TestTIdSipOutboundInvite.SetUp;
begin
  inherited SetUp;

  Self.Core.AddUserAgentListener(Self);

  // We create Self.Dialog in Self.OnDialogEstablished

  Self.DroppedUnmatchedResponse := false;
  Self.InviteMimeType           := SdpMimeType;
  Self.InviteOffer              := TIdSipTestResources.BasicSDP('1.2.3.4');
  Self.OnCallProgressFired      := false;
  Self.OnDialogEstablishedFired := false;
  Self.OnFailureFired           := false;
  Self.OnRedirectFired          := false;
  Self.OnSuccessFired           := false;
end;

procedure TestTIdSipOutboundInvite.TearDown;
begin
  Self.Dialog.Free;

  inherited TearDown;
end;

//* TestTIdSipOutboundInvite Protected methods *********************************

procedure TestTIdSipOutboundInvite.CheckSendDialogEstablishingRequestWithGruu;
var
  Invite: TIdSipOutboundInvite;
begin
  Self.UseGruu;

  Self.MarkSentRequestCount;
  Invite := Self.CreateAction as TIdSipOutboundInvite;
  CheckRequestSent('No request sent');

  CheckEquals(MethodInvite,
              Self.LastSentRequest.Method,
              'Method of sent request');

  CheckEquals(Self.Core.Gruu.Address.Host,
              Invite.LocalGruu.Address.Host,
              'LocalGruu not set');
  Check(Invite.LocalGruu.Address.HasGrid,
        'Local GRUU doesn''t have a "grid" parameter');
end;

function TestTIdSipOutboundInvite.CreateInitialInvite: TIdSipOutboundInitialInvite;
begin
  Result := Self.Core.AddOutboundAction(TIdSipOutboundInitialInvite) as TIdSipOutboundInitialInvite;
  Result.Destination := Self.Destination;
  Result.MimeType    := Self.InviteMimeType;
  Result.Offer       := Self.InviteOffer;
  Result.Send;
end;

//* TestTIdSipOutboundInvite Private methods ***********************************

procedure TestTIdSipOutboundInvite.CheckReceiveFailed(StatusCode: Cardinal);
var
  InviteCount: Integer;
begin
  Self.CreateAction;

  InviteCount := Self.Core.CountOf(MethodInvite);
  Self.ReceiveResponse(StatusCode);

  Check(Self.OnFailureFired,
        'OnFailure didn''t fire after receiving a '
      + IntToStr(StatusCode) + ' response');
  Check(Self.Core.CountOf(MethodInvite) < InviteCount,
        'Invite action not destroyed after receiving a '
      + IntToStr(StatusCode) + ' response');
end;

procedure TestTIdSipOutboundInvite.CheckReceiveOk(StatusCode: Cardinal);
begin
  Self.CreateAction;
  Self.ReceiveResponse(StatusCode);

  Check(Self.OnSuccessFired,
        'OnSuccess didn''t fire after receiving a '
      + IntToStr(StatusCode) + ' response');
end;

procedure TestTIdSipOutboundInvite.CheckReceiveProvisional(StatusCode: Cardinal);
begin
  Self.CreateAction;
  Self.ReceiveResponse(StatusCode);

  Check(Self.OnCallProgressFired,
        'OnCallProgress didn''t fire after receiving a '
      + IntToStr(StatusCode) + ' response');
end;

procedure TestTIdSipOutboundInvite.CheckReceiveRedirect(StatusCode: Cardinal);
begin
  Self.CreateAction;

  Self.ReceiveResponse(StatusCode);

  Check(Self.OnRedirectFired,
        'OnRedirect didn''t fire after receiving a '
      + IntToStr(StatusCode) + ' response');
end;

function TestTIdSipOutboundInvite.CreateArbitraryDialog: TIdSipDialog;
var
  Response: TIdSipResponse;
begin
  Self.Invite.RequestUri := Self.Destination.Address;
  Response := Self.Core.CreateResponse(Self.Invite, SIPOK);
  try
    Result := TIdSipDialog.CreateInboundDialog(Self.Invite, Response, false);
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipOutboundInvite.OnCallProgress(InviteAgent: TIdSipOutboundInvite;
                                                  Response: TIdSipResponse);
begin
  Self.OnCallProgressFired := true;
end;

procedure TestTIdSipOutboundInvite.OnDialogEstablished(InviteAgent: TIdSipOutboundInvite;
                                                       NewDialog: TidSipDialog);
begin
  Self.Dialog := NewDialog.Copy;
  InviteAgent.Dialog := Self.Dialog;

  Self.OnDialogEstablishedFired := true;
  Self.ToHeaderTag := NewDialog.ID.RemoteTag;
end;

procedure TestTIdSipOutboundInvite.OnDroppedUnmatchedMessage(UserAgent: TIdSipAbstractCore;
                                                             Message: TIdSipMessage;
                                                             Receiver: TIdSipTransport);
begin
  Self.DroppedUnmatchedResponse := true;
end;

procedure TestTIdSipOutboundInvite.OnFailure(InviteAgent: TIdSipOutboundInvite;
                                             Response: TIdSipResponse;
                                             const Reason: String);
begin
  Self.OnFailureFired := true;
end;

procedure TestTIdSipOutboundInvite.OnRedirect(Invite: TIdSipOutboundInvite;
                                              Response: TIdSipResponse);
begin
  Self.OnRedirectFired := true;
end;

procedure TestTIdSipOutboundInvite.OnSuccess(InviteAgent: TIdSipOutboundInvite;
                                             Response: TIdSipResponse);
begin
  Self.OnSuccessFired := true;
end;

//* TestTIdSipOutboundInvite Published methods *********************************

procedure TestTIdSipOutboundInvite.TestAbandonAuthentication;
var
  Action: TIdSipOutboundInvite;
begin
  // This test only makes sense for OUTbound actions.
  if Self.IsInboundTest then Exit;

  Self.MarkSentRequestCount;
  Action := Self.CreateAction as TIdSipOutboundInvite;
  CheckRequestSent(Self.ClassName + ': Action didn''t send a request');

  Self.ReceiveUnauthorized(WWWAuthenticateHeader, '');

  Action.Terminate;
  Check(Action.IsTerminated,
        Self.ClassName + ': Action not terminated');
end;

procedure TestTIdSipOutboundInvite.TestAddListener;
var
  L1, L2: TIdSipTestInviteListener;
  Invite: TIdSipOutboundInvite;
begin
  Self.MarkSentRequestCount;
  Invite := Self.CreateAction as TIdSipOutboundInvite;
  CheckRequestSent(Invite.ClassName + ': No INVITE sent');

  L1 := TIdSipTestInviteListener.Create;
  try
    L2 := TIdSipTestInviteListener.Create;
    try
      Invite.AddListener(L1);
      Invite.AddListener(L2);

      Self.ReceiveOk(Self.LastSentRequest);

      Check(L1.Success, 'L1 not informed of success');
      Check(L2.Success, 'L2 not informed of success');
    finally
      L2.Free;
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipOutboundInvite.TestAnswerInAck;
var
  Invite: TIdSipOutboundInvite;
begin
  //  ---       INVITE        --->
  // <--- 200 OK (with offer) ---
  //  ---  ACK (with answer)  --->

  Self.InviteOffer    := '';
  Self.InviteMimeType := '';
  Invite := Self.CreateAction as TIdSipOutboundInvite;

  // Sanity check
  CheckEquals('',
              Self.LastSentRequest.Body,
              'You just sent an INVITE with a body!');

  Invite.Offer    := TIdSipTestResources.BasicSDP('1.2.3.4');
  Invite.MimeType := SdpMimeType;

  Self.MarkSentAckCount;
  Self.ReceiveOkWithBody(Invite.InitialRequest,
                         TIdSipTestResources.BasicSDP('4.3.2.1'),
                         Invite.MimeType);

  CheckAckSent('No ACK sent');
  CheckEquals(Invite.Offer,
              Self.LastSentAck.Body,
              'Incorrect answer');
  CheckEquals(Invite.MimeType,
              Self.LastSentAck.ContentType,
              'Incorrect answer type');
end;

procedure TestTIdSipOutboundInvite.TestCancelAfterAccept;
var
  OutboundInvite: TIdSipOutboundInvite;
begin
  OutboundInvite := Self.CreateAction as TIdSipOutboundInvite;

  Self.ReceiveOk(Self.LastSentRequest);

  Self.MarkSentRequestCount;

  OutboundInvite.Cancel;

  CheckNoRequestSent('Action sent a CANCEL for a fully established call');
end;

procedure TestTIdSipOutboundInvite.TestCancelBeforeAccept;
var
  Invite:            TIdSipRequest;
  InviteCount:       Integer;
  OutboundInvite:    TIdSipOutboundInvite;
  RequestTerminated: TIdSipResponse;
begin
  //  ---         INVITE         --->
  // <---       180 Ringing      ---
  //  ---         CANCEL         --->
  // <---         200 OK         ---  (for the CANCEL)
  // <--- 487 Request Terminated ---  (for the INVITE)
  //  ---           ACK          --->

  //  ---         INVITE         --->
  OutboundInvite := Self.CreateAction as TIdSipOutboundInvite;

  InviteCount := Self.Core.CountOf(MethodInvite);
  Invite := TIdSipRequest.Create;
  try
    Invite.Assign(Self.LastSentRequest);
    // Note that Invite's To header has no tag because we haven't established
    // a dialog.
    RequestTerminated := TIdSipResponse.InResponseTo(Invite, SIPRequestTerminated);
    try
      // <---       180 Ringing      ---
      Self.ReceiveRinging(Invite);

      Check(Self.OnDialogEstablishedFired,
            'No dialog established');

      // Now that we have established a dialog, the Request Terminated response
      // will contain that dialog ID.
      RequestTerminated.ToHeader.Tag := Self.ToHeaderTag;

      Self.MarkSentRequestCount;

      //  ---         CANCEL         --->
      OutboundInvite.Cancel;

      CheckRequestSent('No CANCEL sent');
      CheckEquals(MethodCancel,
                  Self.LastSentRequest.Method,
                  'The request sent wasn''t a CANCEL');
      Check(not OutboundInvite.IsTerminated,
            'No Request Terminated received means no termination');

      // <---         200 OK         ---  (for the CANCEL)
      Self.ReceiveOk(Self.LastSentRequest);

      // <--- 487 Request Terminated ---  (for the INVITE)
      //  ---           ACK          --->
      Self.MarkSentACKCount;
      Self.ReceiveResponse(RequestTerminated);

      CheckAckSent('No ACK sent');

      Check(Self.Core.CountOf(MethodInvite) < InviteCount,
            'Action not terminated');
    finally
      RequestTerminated.Free;
    end;
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipOutboundInvite.TestCancelBeforeProvisional;
var
  Invite:            TIdSipRequest;
  InviteCount:       Integer;
  OutboundInvite:    TIdSipOutboundInvite;
  RequestTerminated: TIdSipResponse;
begin
  //  ---         INVITE         --->
  //  (UAC initiates cancel, but no provisional response = don't send CANCEL yet.)
  // <---       180 Ringing      ---
  // (Ah! A provisional response! Let's send that pending CANCEL)
  //  ---         CANCEL         --->
  // <---         200 OK         ---  (for the CANCEL)
  // <--- 487 Request Terminated ---  (for the INVITE)
  //  ---           ACK          --->

  //  ---         INVITE         --->
  OutboundInvite := Self.CreateAction as TIdSipOutboundInvite;

  InviteCount := Self.Core.CountOf(MethodInvite);
  Invite := TIdSipRequest.Create;
  try
    Invite.Assign(Self.LastSentRequest);
    // Note that Invite's To header has no tag because we haven't established
    // a dialog. Therefore the RequestTerminated won't match the INVITE's
    // dialog - we have to wait until the action receives the 180 Ringing before
    // we can set the To tag.
    RequestTerminated := TIdSipResponse.InResponseTo(Invite, SIPRequestTerminated);
    try
      Self.MarkSentRequestCount;

      OutboundInvite.Cancel;

      CheckNoRequestSent('CANCEL sent before the session receives a '
                       + 'provisional response');

      Check(not OutboundInvite.IsTerminated,
            'No Request Terminated received means no termination');

     // <---       180 Ringing      ---
     //  ---         CANCEL         --->
     Self.ReceiveRinging(Self.LastSentRequest);
     Check(Self.OnDialogEstablishedFired,
           'No dialog established');
     // Now that we have the remote tag we can:
     RequestTerminated.ToHeader.Tag := Self.ToHeaderTag;

      // <---         200 OK         ---  (for the CANCEL)
      Self.ReceiveOk(Self.LastSentRequest);

      // <--- 487 Request Terminated ---  (for the INVITE)
      //  ---           ACK          --->

      Self.MarkSentACKCount;
      Self.ReceiveResponse(RequestTerminated);

      CheckAckSent('No ACK sent');

      Check(Self.Core.CountOf(MethodInvite) < InviteCount,
            'Action not terminated');
    finally
      RequestTerminated.Free;
    end;
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipOutboundInvite.TestCancelReceiveInviteOkBeforeCancelOk;
var
  Action: TIdSipOutboundInvite;
  Cancel: TIdSipRequest;
  Invite: TIdSipRequest;
begin
  //  ---          INVITE         --->
  // <---        100 Trying       ---
  //  ---          CANCEL         --->
  // <--- 200 OK (for the INVITE) ---
  //  ---           ACK           --->
  // <--- 200 OK (for the CANCEL) ---
  //  ---           BYE           --->
  // <---   200 OK (for the BYE)  ---

  Action := Self.CreateAction as TIdSipOutboundInvite;

  Invite := TIdSipRequest.Create;
  try
    Cancel := TIdSipRequest.Create;
    try
      Invite.Assign(Self.LastSentRequest);
      Self.ReceiveTrying(Invite);

      Action.Cancel;
      Cancel.Assign(Self.LastSentRequest);

      Self.MarkSentAckCount;
      Self.MarkSentRequestCount;
      Self.ReceiveOk(Invite);
      Self.ReceiveOk(Cancel);

      CheckRequestSent('No request sent to terminate the cancelled session');
      CheckEquals(MethodBye,
                  Self.LastSentRequest.Method,
                  'Terminating request');

      CheckAckSent('No ACK sent in response to the 2xx');
      CheckEquals(Invite.Body,
                  Self.LastSentAck.Body,
                  'ACK body');
      CheckEquals(Invite.ContentType,
                  Self.LastSentAck.ContentType,
                  'ACK Content-Type');
      Check(Invite.ContentDisposition.Equals(Self.LastSentAck.ContentDisposition),
            'ACK Content-Disposition');
    finally
      Cancel.Free;
    end;
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipOutboundInvite.TestInviteTwice;
var
  Invite: TIdSipAction;
begin
  Invite := Self.CreateAction;

  try
    Invite.Send;
    Fail('Failed to bail out calling Invite a 2nd time');
  except
    on EIdSipTransactionUser do;
  end;
end;

procedure TestTIdSipOutboundInvite.TestIsInvite;
begin
  Check(Self.CreateAction.IsInvite, 'INVITE action not marked as such');
end;

procedure TestTIdSipOutboundInvite.TestMethod;
begin
  CheckEquals(MethodInvite,
              TIdSipOutboundInvite.Method,
              'Outbound INVITE Method');
end;

procedure TestTIdSipOutboundInvite.TestOfferInInvite;
begin
  //  ---    INVITE (with offer)   --->
  // <---   200 OK (with answer)   ---
  //  --- ACK (with copy of offer) --->

  Self.MarkSentRequestCount;
  Self.CreateAction;
  CheckRequestSent('No initial INVITE sent');

  CheckEquals(Self.InviteOffer,
              Self.LastSentRequest.Body,
              'Body of INVITE');
  CheckEquals(Self.InviteMimeType,
              Self.LastSentRequest.ContentType,
              'Content-Type of INVITE');

  Self.MarkSentAckCount;
  Self.ReceiveOkWithBody(Self.LastSentRequest,
                         TIdSipTestResources.BasicSDP('4.3.2.1'),
                         SdpMimeType);

  CheckAckSent('No ACK sent');
  CheckEquals(Self.LastSentRequest.Body,
              Self.LastSentAck.Body,
              'Body of ACK doesn''t match INVITE');
  CheckEquals(Self.LastSentRequest.ContentType,
              Self.LastSentAck.ContentType,
              'Content-Type of ACK doesn''t match INVITE');
end;

procedure TestTIdSipOutboundInvite.TestReceive2xxSchedulesTransactionCompleted;
var
  Invite: TIdSipAction;
begin
  // RFC 3261, section 13.2.2.4 says
  //   The UAC core considers the INVITE transaction completed 64*T1 seconds
  //   after the reception of the first 2xx response.  At this point all the
  //   early dialogs that have not transitioned to established dialogs are
  //   terminated.  Once the INVITE transaction is considered completed by
  //   the UAC core, no more new 2xx responses are expected to arrive.
  //
  // This test makes sure we don't schedule this when we send the INVITE.

  Invite := Self.CreateAction;
  Self.DebugTimer.TriggerAllEventsOfType(TIdSipActionsWait);

  Check(not Invite.IsTerminated,
        'OutboundInvite terminated prematurely: it incorrectly scheduled '
      + 'a TIdSipOutboundInviteTransactionComplete');

  Self.ReceiveOk(Self.LastSentRequest);

  Self.DebugTimer.TriggerAllEventsOfType(TIdSipActionsWait);

  Check(Invite.IsTerminated,
        'OutboundInvite didn''t schedule a TIdSipOutboundInviteTransactionComplete');
end;

procedure TestTIdSipOutboundInvite.TestReceiveProvisional;
var
  StatusCode: Integer;
begin
  StatusCode := SIPLowestProvisionalCode;
//  for StatusCode := SIPLowestProvisionalCode to SIPHighestProvisionalCode do
    Self.CheckReceiveProvisional(StatusCode);
end;

procedure TestTIdSipOutboundInvite.TestReceiveGlobalFailed;
var
  StatusCode: Integer;
begin
  StatusCode := SIPLowestGlobalFailureCode;
//  for StatusCode := SIPLowestGlobalFailureCode to SIPHighestGlobalFailureCode do
    Self.CheckReceiveFailed(StatusCode);
end;

procedure TestTIdSipOutboundInvite.TestReceiveOk;
var
  StatusCode: Integer;
begin
  StatusCode := SIPLowestOkCode;
//  for StatusCode := SIPLowestOkCode to SIPHighestOkCode do
    Self.CheckReceiveOk(StatusCode);
end;

procedure TestTIdSipOutboundInvite.TestReceiveRedirect;
var
  StatusCode: Integer;
begin
  StatusCode := SIPLowestRedirectionCode;
//  for StatusCode := SIPLowestRedirectionCode to SIPHighestRedirectionCode do
    Self.CheckReceiveRedirect(StatusCode);
end;

procedure TestTIdSipOutboundInvite.TestReceiveRequestFailed;
var
  StatusCode: Integer;
begin
  StatusCode := SIPLowestFailureCode;

//  for StatusCode := SIPLowestFailureCode to SIPUnauthorized - 1 do
    Self.CheckReceiveFailed(StatusCode);
{
  for StatusCode := SIPUnauthorized + 1 to SIPProxyAuthenticationRequired - 1 do
    Self.CheckReceiveFailed(StatusCode);

  for StatusCode := SIPProxyAuthenticationRequired + 1 to SIPHighestFailureCode do
    Self.CheckReceiveFailed(StatusCode);
}
end;

procedure TestTIdSipOutboundInvite.TestReceiveRequestFailedAfterAckSent;
var
  InviteRequest: TIdSipRequest;
begin
  //  ---          INVITE         --->
  // <---          200 OK         ---
  //  ---           ACK           --->
  // <--- 503 Service Unavailable ---

  // This situation should never arise: the remote end's sending a failure
  // response to a request it has already accepted. Still, I've seen it happen
  // once before...

  Self.CreateAction;

  InviteRequest := TIdSipRequest.Create;
  try
    InviteRequest.Assign(Self.LastSentRequest);

    Self.MarkSentAckCount;
    Self.ReceiveOk(InviteRequest);
    CheckAckSent('No ACK sent');

    Self.ReceiveServiceUnavailable(InviteRequest);

    Check(Self.DroppedUnmatchedResponse,
          'Invite action didn''t terminate, so the Transaction-User core '
        + 'didn''t drop the message');
  finally
    InviteRequest.Free;
  end;
end;

procedure TestTIdSipOutboundInvite.TestReceiveServerFailed;
var
  StatusCode: Integer;
begin
  StatusCode := SIPLowestServerFailureCode;
//  for StatusCode := SIPLowestServerFailureCode to SIPHighestServerFailureCode do
    Self.CheckReceiveFailed(StatusCode);
end;

procedure TestTIdSipOutboundInvite.TestRemoveListener;
var
  L1, L2: TIdSipTestInviteListener;
  Invite: TIdSipOutboundInvite;
begin
  Invite := Self.CreateAction as TIdSipOutboundInvite;

  L1 := TIdSipTestInviteListener.Create;
  try
    L2 := TIdSipTestInviteListener.Create;
    try
      Invite.AddListener(L1);
      Invite.AddListener(L2);
      Invite.RemoveListener(L2);

      Self.ReceiveOk(Self.LastSentRequest);

      Check(L1.Success,
            'First listener not notified');
      Check(not L2.Success,
            'Second listener erroneously notified, ergo not removed');
    finally
      L2.Free
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipOutboundInvite.TestSendTwice;
var
  Invite: TIdSipAction;
begin
  Invite := Self.CreateAction;
  try
    Invite.Send;
    Fail(Invite.ClassName + ': Failed to bail out calling Send a 2nd time');
  except
    on EIdSipTransactionUser do;
  end;
end;

procedure TestTIdSipOutboundInvite.TestSendWithGruu;
var
  Invite: TIdSipOutboundInvite;
begin
  Self.UseGruu;

  Self.MarkSentRequestCount;
  Invite := Self.CreateAction as TIdSipOutboundInvite;
  CheckRequestSent(Self.ClassName + ': No request sent');

  CheckEquals(MethodInvite,
              Self.LastSentRequest.Method,
              Self.ClassName + ': Method of sent request');

  CheckEquals(Self.Core.Gruu.Address.Host,
              Invite.LocalGruu.Address.Host,
              Self.ClassName + ': LocalGruu not set');
  Check(not Invite.LocalGruu.Address.HasGrid,
        Self.ClassName + ': Local GRUU has a "grid" parameter but isn''t a '
      + 'dialog-creating request');
end;

procedure TestTIdSipOutboundInvite.TestTerminateBeforeAccept;
var
  OutboundInvite: TIdSipOutboundInvite;
begin
  //  ---         INVITE         --->
  // <---       180 Ringing      ---
  //  ---         CANCEL         --->
  // <---         200 OK         --- (for the CANCEL)
  // <--- 487 Request Terminated ---
  //  ---          ACK           --->
  OutboundInvite := Self.CreateAction as TIdSipOutboundInvite;
  Self.ReceiveRinging(Self.LastSentRequest);
  Self.MarkSentRequestCount;

  OutboundInvite.Terminate;

  CheckRequestSent(Self.ClassName + ': Action didn''t send a CANCEL');
  Check(not OutboundInvite.IsTerminated,
        'The Action can''t terminate until it receives the 487 Request '
      + 'Terminated response');

  Self.ReceiveResponse(OutboundInvite.InitialRequest, SIPRequestTerminated);
  Check(OutboundInvite.IsTerminated,
        'The 487 arrived but the Action didn''t terminate');
end;

procedure TestTIdSipOutboundInvite.TestTerminateAfterAccept;
var
  OutboundInvite: TIdSipOutboundInvite;
begin
  //  --- INVITE --->
  // <--- 200 OK ---
  //  ---  ACK   --->
  //  ---  BYE   --->
  // <--- 200 OK ---
  OutboundInvite := Self.CreateAction as TIdSipOutboundInvite;

  Self.ReceiveOk(Self.LastSentRequest);

  Self.MarkSentRequestCount;

  OutboundInvite.Terminate;

  CheckNoRequestSent('Action sent a CANCEL for a fully established call');
end;

procedure TestTIdSipOutboundInvite.TestTransactionCompleted;
var
  Invite: TIdSipOutboundInvite;
begin
  Invite := Self.CreateAction as TIdSipOutboundInvite;
  Invite.TransactionCompleted;
  Check(Invite.IsTerminated, 'Outbound INVITE not marked as terminated');
end;

//******************************************************************************
//* TestTIdSipOutboundInitialInvite                                            *
//******************************************************************************
//* TestTIdSipOutboundInitialInvite Protected methods **************************

function TestTIdSipOutboundInitialInvite.CreateAction: TIdSipAction;
var
  Invite: TIdSipOutboundInitialInvite;
begin
  Result := Self.Core.AddOutboundAction(TIdSipOutboundInitialInvite);

  Invite := Result as TIdSipOutboundInitialInvite;
  Invite.Destination := Self.Destination;
  Invite.MimeType    := Self.InviteMimeType;
  Invite.Offer       := Self.InviteOffer;
  Invite.AddListener(Self);
  Invite.Send;
end;

//* TestTIdSipOutboundInitialInvite Published methods **************************

procedure TestTIdSipOutboundInitialInvite.TestSendWithGruu;
begin
  Self.CheckSendDialogEstablishingRequestWithGruu;
end;

//******************************************************************************
//* TestTIdSipOutboundRedirectedInvite                                         *
//******************************************************************************
//* TestTIdSipOutboundRedirectedInvite Protected methods ***********************

function TestTIdSipOutboundRedirectedInvite.CreateAction: TIdSipAction;
begin
  // We do this to send the initial INVITE
  Self.CreateInitialInvite;

  // Then we send the redirected INVITE
  Result := Self.CreateInvite;
end;

//* TestTIdSipOutboundRedirectedInvite Private methods *************************

function TestTIdSipOutboundRedirectedInvite.CreateInvite: TIdSipOutboundRedirectedInvite;
begin
  Result := Self.Core.AddOutboundAction(TIdSipOutboundRedirectedInvite) as TIdSipOutboundRedirectedInvite;
  Result.Contact        := Self.Destination;
  Result.OriginalInvite := Self.LastSentRequest;
  Result.AddListener(Self);
  Result.Send;
end;

//* TestTIdSipOutboundRedirectedInvite Published methods ***********************

procedure TestTIdSipOutboundRedirectedInvite.TestRedirectedInvite;
var
  Invite:         TIdSipOutboundRedirectedInvite;
  NewInvite:      TIdSipRequest;
  OriginalInvite: TIdSipRequest;
begin
  OriginalInvite := TIdSipRequest.Create;
  try
    Self.CreateInitialInvite;
    OriginalInvite.Assign(Self.LastSentRequest);

    Self.MarkSentRequestCount;

    Invite := Self.CreateInvite;

    CheckRequestSent('No INVITE sent');

    NewInvite := Invite.InitialRequest;

    CheckEquals(OriginalInvite.CallID,
                NewInvite.CallID,
                'Call-ID mismatch between original and new INVITEs');
    CheckEquals(OriginalInvite.From.Tag,
                NewInvite.From.Tag,
                'From tag mismatch between original and new INVITEs');
    Check(not NewInvite.ToHeader.HasTag,
          'New INVITE mustn''t have a To tag');
  finally
    OriginalInvite.Free;
  end;
end;

procedure TestTIdSipOutboundRedirectedInvite.TestSendWithGruu;
begin
  Self.CheckSendDialogEstablishingRequestWithGruu;
end;

//******************************************************************************
//* TestTIdSipOutboundReInvite                                                 *
//******************************************************************************
//* TestTIdSipOutboundReInvite Public methods **********************************

procedure TestTIdSipOutboundReInvite.SetUp;
begin
  inherited SetUp;

  Self.Dialog := Self.CreateArbitraryDialog;
end;

procedure TestTIdSipOutboundReInvite.TearDown;
begin
  Self.Dialog.Free;

  inherited TearDown;
end;

//* TestTIdSipOutboundReInvite Protected methods *******************************

function TestTIdSipOutboundReInvite.CreateAction: TIdSipAction;
var
  Invite: TIdSipOutboundReInvite;
begin
  Self.Dialog.RemoteTarget.Uri := Self.Destination.Address.Uri;

  Invite := Self.CreateInvite;
  Invite.Dialog         := Self.Dialog;
  Invite.MimeType       := Self.InviteMimeType;
  Invite.Offer          := Self.InviteOffer;
  Invite.OriginalInvite := Self.Invite;
  Invite.AddListener(Self);
  Invite.Send;

  Result := Invite;
end;

//* TestTIdSipOutboundReInvite Private methods *********************************

function TestTIdSipOutboundReInvite.CreateInvite: TIdSipOutboundReInvite;
begin
  Result := Self.Core.AddOutboundAction(TIdSipOutboundReInvite) as TIdSipOutboundReInvite;
end;

//******************************************************************************
//* TestTIdSipOutboundReplacingInvite                                          *
//******************************************************************************
//* TestTIdSipOutboundReplacingInvite Public methods ***************************

procedure TestTIdSipOutboundReplacingInvite.SetUp;
begin
  inherited SetUp;

  Self.CallID  := 'call@localhost';
  Self.FromTag := 'fromtag';
  Self.ToTag   := 'totag';
end;

procedure TestTIdSipOutboundReplacingInvite.TearDown;
begin
  inherited TearDown;
end;

//* TestTIdSipOutboundReplacingInvite Protected methods ************************

function TestTIdSipOutboundReplacingInvite.CreateAction: TIdSipAction;
var
  Invite: TIdSipOutboundReplacingInvite;
begin
  Invite := Self.CreateInvite;
  Invite.CallID  := Self.CallID;
  Invite.FromTag := Self.FromTag;
  Invite.ToTag   := Self.ToTag;

  Invite.Destination := Self.Destination;
  Invite.Dialog      := Self.Dialog;
  Invite.MimeType    := Self.InviteMimeType;
  Invite.Offer       := Self.InviteOffer;
  Invite.AddListener(Self);
  Invite.Send;

  Result := Invite;
end;

//* TestTIdSipOutboundReplacingInvite Private methods **************************

function TestTIdSipOutboundReplacingInvite.CreateInvite: TIdSipOutboundReplacingInvite;
begin
  Result := Self.Core.AddOutboundAction(TIdSipOutboundReplacingInvite) as TIdSipOutboundReplacingInvite;
end;

//* TestTIdSipOutboundReplacingInvite Published methods ************************

procedure TestTIdSipOutboundReplacingInvite.TestSend;
var
  Invite: TIdSipRequest;
begin
  Self.MarkSentRequestCount;
  Self.CreateAction;
  CheckRequestSent(Self.ClassName + ': No request sent');

  Invite := Self.LastSentRequest;
  CheckEquals(MethodInvite,
              Invite.Method,
              Self.ClassName + ': wrong request type sent');
  CheckEquals(Self.CallID,
              Invite.Replaces.CallID,
              Self.ClassName + ': Replaces'' Call-ID');
  CheckEquals(Self.FromTag,
              Invite.Replaces.FromTag,
              Self.ClassName + ': Replaces'' from-tag');
  CheckEquals(Self.ToTag,
              Invite.Replaces.ToTag,
              Self.ClassName + ': Replaces'' to-tag');
end;

//******************************************************************************
//* TestTIdSipSession                                                          *
//******************************************************************************
//* TestTIdSipSession Public methods *******************************************

procedure TestTIdSipSession.SetUp;
begin
  inherited SetUp;

  Self.Module := Self.Core.ModuleFor(MethodInvite) as TIdSipInviteModule;

  Self.MultiStreamSdp := Self.CreateMultiStreamSdp;
  Self.SimpleSdp      := Self.CreateSimpleSdp;

  Self.MimeType                  := '';
  Self.OnEndedSessionFired       := false;
  Self.OnEstablishedSessionFired := false;
  Self.OnModifiedSessionFired    := false;
  Self.OnModifySessionFired      := false;
  Self.OnReferralFired           := false;
  Self.RemoteSessionDescription  := '';
end;

procedure TestTIdSipSession.TearDown;
begin
  Self.SimpleSdp.Free;
  Self.MultiStreamSdp.Free;

  inherited TearDown;
end;

//* TestTIdSipSession Protected methods ****************************************

procedure TestTIdSipSession.CheckHeadersEqual(ExpectedMessage: TIdSipMessage;
                                              ReceivedMessage: TIdSipMessage;
                                              const HeaderName: String;
                                              const Msg: String);
var
  ExpectedHeaders: TIdSipHeadersFilter;
  I:               Integer;
  ReceivedHeaders: TIdSipHeadersFilter;
begin
  ExpectedHeaders := TIdSipHeadersFilter.Create(ExpectedMessage.Headers,
                                                ProxyAuthorizationHeader);
  try
    ReceivedHeaders := TIdSipHeadersFilter.Create(ReceivedMessage.Headers,
                                                  ProxyAuthorizationHeader);
    try
      I := 0;
      ExpectedHeaders.First;
      ReceivedHeaders.First;

      while ExpectedHeaders.HasNext and ReceivedHeaders.HasNext do begin
        CheckEquals(ExpectedHeaders.CurrentHeader.FullValue,
                    ReceivedHeaders.CurrentHeader.FullValue,
                    Msg + ': Header mismatch at index ' + IntToStr(I));

        ExpectedHeaders.Next;
        ReceivedHeaders.Next;
        Inc(I);
      end;

      Check(ExpectedHeaders.HasNext = ReceivedHeaders.HasNext,
            Msg + ': Number of headers doesn''t match');
    finally
      ReceivedHeaders.Free;
    end;
  finally
    ExpectedHeaders.Free;
  end;
end;

procedure TestTIdSipSession.CheckResendWaitTime(Milliseconds: Cardinal;
                                                const Msg: String);
begin
  Check(Milliseconds mod 10 = 0, Msg);
end;

function TestTIdSipSession.CreateAndEstablishSession: TIdSipSession;
var
  NewSession: TIdSipSession;
begin
  NewSession := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(NewSession);

  Result := NewSession;
end;

function TestTIdSipSession.CreateMultiStreamSdp: TIdSdpPayload;
var
  Connection: TIdSdpConnection;
  MD:         TIdSdpMediaDescription;
begin
  Result := TIdSdpPayload.Create;
  Result.Version                := 0;

  Result.Origin.Username        := 'wintermute';
  Result.Origin.SessionID       := '2890844526';
  Result.Origin.SessionVersion  := '2890842807';
  Result.Origin.NetType         := Id_SDP_IN;
  Result.Origin.AddressType     := Id_IPv4;
  Result.Origin.Address         := '127.0.0.1';

  Result.SessionName            := 'Minimum Session Info';

  Connection := Result.AddConnection;
  Connection.NetType     := Id_SDP_IN;
  Connection.AddressType := Id_IPv4;
  Connection.Address     := '127.0.0.1';

  MD := Result.AddMediaDescription;
  MD.MediaType := mtAudio;
  MD.Port      := 10000;
  MD.Transport := AudioVisualProfile;
  MD.AddFormat('0');

  MD := Result.AddMediaDescription;
  MD.MediaType := mtText;
  MD.Port      := 11000;
  MD.Transport := AudioVisualProfile;
  MD.AddFormat('98');
  MD.AddAttribute(RTPMapAttribute, '98 t140/1000');
end;

function TestTIdSipSession.CreateRemoteReInvite(LocalDialog: TIdSipDialog): TIdSipRequest;
begin
  Result := Self.Module.CreateReInvite(LocalDialog,
                                       Self.SimpleSdp.AsString,
                                       Self.SimpleSdp.MimeType);
  try
    Result.ToHeader.Tag    := LocalDialog.ID.LocalTag;
    Result.From.Tag        := LocalDialog.ID.RemoteTag;
    Result.CSeq.SequenceNo := LocalDialog.RemoteSequenceNo + 1;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TestTIdSipSession.CreateSimpleSdp: TIdSdpPayload;
var
  Connection: TIdSdpConnection;
  MD:         TIdSdpMediaDescription;
begin
  Result := TIdSdpPayload.Create;
  Result.Version               := 0;

  Result.Origin.Username       := 'wintermute';
  Result.Origin.SessionID      := '2890844526';
  Result.Origin.SessionVersion := '2890842807';
  Result.Origin.NetType        := Id_SDP_IN;
  Result.Origin.AddressType    := Id_IPv4;
  Result.Origin.Address        := '127.0.0.1';

  Result.SessionName           := 'Minimum Session Info';

  MD := Result.AddMediaDescription;
  MD.MediaType := mtText;
  MD.Port      := 11000;
  MD.Transport := AudioVisualProfile;
  MD.AddFormat('98');
  MD.AddAttribute(RTPMapAttribute, '98 t140/1000');

  MD.Connections.Add(TIdSdpConnection.Create);
  Connection := MD.Connections[0];
  Connection.NetType     := Id_SDP_IN;
  Connection.AddressType := Id_IPv4;
  Connection.Address     := '127.0.0.1';
end;

procedure TestTIdSipSession.OnDroppedUnmatchedMessage(UserAgent: TIdSipAbstractCore;
                                                      Message: TIdSipMessage;
                                                      Receiver: TIdSipTransport);
begin
  Self.DroppedUnmatchedResponse := true;
end;

procedure TestTIdSipSession.OnEndedSession(Session: TIdSipSession;
                                           ErrorCode: Cardinal;
                                           const Reason: String);
begin
  Self.OnEndedSessionFired := true;
  Self.ErrorCode           := ErrorCode;
  Self.Reason              := Reason;
end;

procedure TestTIdSipSession.OnEstablishedSession(Session: TIdSipSession;
                                                 const RemoteSessionDescription: String;
                                                 const MimeType: String);
begin
  Self.OnEstablishedSessionFired := true;
end;

procedure TestTIdSipSession.OnModifiedSession(Session: TIdSipSession;
                                              Answer: TIdSipResponse);
begin
  Self.OnModifiedSessionFired := true;

  Self.RemoteSessionDescription := Answer.Body;
  Self.MimeType                 := Answer.ContentType;
end;

procedure TestTIdSipSession.OnModifySession(Session: TIdSipSession;
                                            const RemoteSessionDescription: String;
                                            const MimeType: String);
begin
  Self.OnModifySessionFired := true;

  Self.RemoteSessionDescription := RemoteSessionDescription;
  Self.MimeType                 := MimeType;
end;

procedure TestTIdSipSession.OnProgressedSession(Session: TIdSipSession;
                                                Progress: TIdSipResponse);
begin
  // Do nothing.
end;

procedure TestTIdSipSession.OnReferral(Session: TIdSipSession;
                                       Refer: TIdSipRequest);
begin
  Self.OnReferralFired := true;
end;

procedure TestTIdSipSession.ReceiveRemoteReInvite(Session: TIdSipSession);
begin
  // At this point Invite represents the INVITE we sent out
  Self.Invite.LastHop.Branch  := Self.Invite.LastHop.Branch + '1';
  Self.Invite.CallID          := Session.Dialog.ID.CallID;
  Self.Invite.From.Tag        := Session.Dialog.ID.RemoteTag;
  Self.Invite.ToHeader.Tag    := Session.Dialog.ID.LocalTag;
  Self.Invite.CSeq.SequenceNo := Session.Dialog.RemoteSequenceNo + 1;

  Self.Invite.Body          := Self.RemoteSessionDescription;
  Self.Invite.ContentType   := Self.MimeType;
  Self.Invite.ContentLength := Length(Self.Invite.Body);

  // Now it represents an INVITE received from the network
  Self.ReceiveRequest(Self.Invite)
end;

procedure TestTIdSipSession.ResendWith(Session: TIdSipSession;
                                       AuthenticationChallenge: TIdSipResponse);
var
  AuthCreds: TIdSipAuthorizationHeader;
begin
  AuthCreds := Self.CreateAuthorization(AuthenticationChallenge);
  try
    Session.Resend(AuthCreds);
  finally
    AuthCreds.Free;
  end;
end;

//* TestTIdSipSession Published methods ****************************************

procedure TestTIdSipSession.TestAckToInDialogInviteMatchesInvite;
var
  Ack:     TIdSipRequest;
  Session: TIdSipSession;
begin
  Session := Self.CreateAndEstablishSession;
  Self.ReceiveRemoteReInvite(Session);

  Check(Self.OnModifySessionFired
        Session.ClassName + ': OnModifySession didn''t fire');

  Session.AcceptModify('', '');

  // The last request was the inbound re-INVITE.
  Ack := Self.Dispatcher.Transport.LastRequest.AckFor(Self.LastSentResponse);
  try
    Check(not Session.Match(Ack),
          Session.ClassName + ': ACK mustn''t match the Session');
  finally
    Ack.Free;
  end;
end;

procedure TestTIdSipSession.TestByeCarriesInviteAuthorization;
var
  Invite:  TIdSipRequest;
  Session: TIdSipOutboundSession;
begin
  //  ---              INVITE               --->
  // <--- 407 Proxy Authentication Required ---
  //  ---               ACK                 --->
  //  ---              INVITE               ---> (with proxy credentials)
  // <--- 407 Proxy Authentication Required ---
  //  ---               ACK                 --->
  //  ---              INVITE               ---> (with 2x proxy credentials)
  // <---         401 Unauthorized          ---
  //  ---               ACK                 --->
  //  ---              INVITE               ---> (with 2x proxy, UA credentials)
  // <---              200 OK               ---
  //  ---               ACK                 --->
  // ===========================================
  //                Media streams
  // ===========================================
  //  ---               BYE                 ---> (with 2x proxy, UA credentials)

  Session := Self.Module.Call(Self.Destination, '', '');

  // 1st proxy challenge
  Session.Send;
  Self.ReceiveUnauthorized(ProxyAuthenticateHeader, '');
  Check(not Self.DroppedUnmatchedResponse,
        'First 407 Proxy Authentication Required dropped');

  // 2nd proxy challenge
  Self.ResendWith(Session, Self.Dispatcher.Transport.LastResponse);
  Self.ReceiveUnauthorized(ProxyAuthenticateHeader, QopAuthInt);
  Check(not Self.DroppedUnmatchedResponse,
        'Second 407 Proxy Authentication Required dropped');

  // UA challenge
  Self.ResendWith(Session, Self.Dispatcher.Transport.LastResponse);
  Self.ReceiveUnauthorized(WWWAuthenticateHeader, '');
  Check(not Self.DroppedUnmatchedResponse,
        '401 Unauthorized dropped');

  Self.ResendWith(Session, Self.Dispatcher.Transport.LastResponse);
  Self.ReceiveOk(Self.LastSentRequest);
  Check(not Self.DroppedUnmatchedResponse,
        '200 OK dropped');

  Invite := Self.LastSentRequest.Copy as TIdSipRequest;
  try
    Check(Session.DialogEstablished,
          'Dialog not established: did something drop a message? '
        + 'DroppedUnmatchedResponse = ' + Self.BoolToStr(Self.DroppedUnmatchedResponse));

    Self.MarkSentRequestCount;
    Session.Terminate;
    CheckRequestSent('No BYE sent');
    CheckEquals(MethodBye,
                Self.LastSentRequest.Method,
                'Unexpected message sent to terminate a session');
    Check(Self.LastSentRequest.HasAuthorizationFor(Invite.FirstAuthorization.Realm),
          'BYE''s missing INVITE''s credentials: Authorization');
    CheckHeadersEqual(Invite, Self.LastSentRequest, ProxyAuthorizationHeader,
                      'BYE''s Proxy-Authorization');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipSession.TestDontMatchResponseToModify;
var
  Ok:      TIdSipResponse;
  Session: TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);
  Check(Session.DialogEstablished,
        Session.ClassName + ': No dialog established');
  Session.Modify('', '');

  Ok := TIdSipResponse.InResponseTo(Self.LastSentRequest,
                                    SIPOK);
  try
    Check(not Session.Match(Ok),
          Session.ClassName + ': Responses to outbound re-INVITEs must only '
        + 'match the OutboundInvites');
  finally
    Ok.Free;
  end;
end;

procedure TestTIdSipSession.TestDontMatchResponseToInitialRequest;
var
  Ok:      TIdSipResponse;
  Session: TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;

  Ok := TIdSipResponse.InResponseTo(Session.InitialRequest, SIPOK);
  try
    Ok.ToHeader.Tag := Self.Core.NextTag; // Just for completeness' sake
    Check(not Session.Match(Ok),
          Session.ClassName + ': Responses to the initial INVITE must only '
        + 'match the (In|Out)boundInvite');
  finally
    Ok.Free;
  end;
end;

procedure TestTIdSipSession.TestInboundModify;
var
  LocalSessionDescription: String;
  LocalMimeType:           String;
  OK:                      TIdSipResponse;
  Session:                 TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);

  LocalMimeType                 := SdpMimeType;
  LocalSessionDescription       := Format(DummySDP, ['127.0.0.1']);
  Self.MimeType                 := SdpMimeType;
  Self.RemoteSessionDescription := Self.SimpleSdp.AsString;

  Self.ReceiveRemoteReInvite(Session);

  Self.MarkSentResponseCount;
  Session.AcceptModify(LocalSessionDescription, LocalMimeType);
  CheckResponseSent('No response sent');
  OK := Self.LastSentResponse;
  Check(OK.ToHeader.HasTag,
        'To header of 200 OK lacks a tag');
  Check(OK.From.HasTag,
        'From header of 200 OK lacks a tag');

  Self.ReceiveAck;

  Check(Self.OnModifySessionFired,
        Session.ClassName + ': OnModifySession didn''t fire');
  CheckEquals(MimeType,
              Session.LocalMimeType,
              'Session.LocalMimeType');
  CheckEquals(LocalSessionDescription,
              Session.LocalSessionDescription,
              'Session.LocalSessionDescription');
  CheckEquals(Self.MimeType,
              Session.RemoteMimeType,
              'Session.RemoteMimeType');
  CheckEquals(Self.RemoteSessionDescription,
              Session.RemoteSessionDescription,
              'Session.RemoteSessionDescription');
end;

procedure TestTIdSipSession.TestIsSession;
var
  Action: TIdSipAction;
begin
  Action := Self.CreateAction;
  // Self.UA owns the action!
  Check(Action.IsSession,
        Action.ClassName + ' not marked as a Session');
end;

procedure TestTIdSipSession.TestMatchBye;
var
  Bye:     TIdSipRequest;
  Session: TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);
  Check(Session.DialogEstablished,
        Session.ClassName + ': No dialog established');

  Bye := Self.CreateRemoteReInvite(Session.Dialog);
  try
    Bye.Method := MethodBye;

    Check(Session.Match(Bye),
          Session.ClassName + ': BYE must match session');
  finally
    Bye.Free;
  end;
end;

procedure TestTIdSipSession.TestMatchInitialRequest;
var
  Session: TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;

  Check(not Session.Match(Session.InitialRequest),
        Session.ClassName + ': The initial INVITE must only match the '
      + '(In|Out)boundInvite');
end;

procedure TestTIdSipSession.TestMatchInboundModify;
var
  ReInvite: TIdSipRequest;
  Session:  TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);
  Check(Session.DialogEstablished,
        Session.ClassName + ': No dialog established');

  ReInvite := Self.CreateRemoteReInvite(Session.Dialog);
  try
    Check(Session.Match(ReInvite),
          Session.ClassName + ': In-dialog INVITE must match session');
  finally
    ReInvite.Free;
  end;
end;

procedure TestTIdSipSession.TestMatchInboundModifyAck;
var
  Ack:     TIdSipRequest;
  Session: TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);
  Check(Session.DialogEstablished,
        Session.ClassName + ': No dialog established');

  Self.ReceiveRemoteReInvite(Session);
  Session.AcceptModify('', '');

  Self.DroppedUnmatchedResponse := false;
  Ack := Self.Dispatcher.Transport.LastRequest.AckFor(Self.LastSentResponse);
  try
    Check(not Session.Match(Ack),
          Session.ClassName
        + ': ACK for in-dialog INVITE must not match session');

    Self.ReceiveRequest(Ack);
    Check(not Self.DroppedUnmatchedResponse,
          Session.ClassName + ': Dropped ACK for in-dialog INVITE');
  finally
    Ack.Free;
  end;
end;

procedure TestTIdSipSession.TestMatchReferWithCorrectGridParameter;
var
  Refer:   TIdSipRequest;
  Session: TIdSipSession;
  SubMod:  TIdSipSubscribeModule;
begin
  Self.UseGruu;

  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);

  SubMod := Self.Core.AddModule(TIdSipSubscribeModule) as TIdSipSubscribeModule;
  Refer := SubMod.CreateRefer(Self.Destination, Self.Destination);
  try
    Refer.RequestUri.Grid := Session.LocalGruu.Grid;

    Check(Session.Match(Refer),
          'Session should match any request whose "grid" parameter matches that '
        + 'of the GRUU that the stack sent out in creating this session');
  finally
    Refer.Free;
  end;
end;

procedure TestTIdSipSession.TestMatchReferWithIncorrectGridParameter;
var
  Refer:   TIdSipRequest;
  Session: TIdSipSession;
  SubMod:  TIdSipSubscribeModule;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);

  SubMod := Self.Core.AddModule(TIdSipSubscribeModule) as TIdSipSubscribeModule;
  Refer := SubMod.CreateRefer(Self.Destination, Self.Destination);
  try
    if Session.IsInbound then
      Refer.RequestUri := Session.InitialRequest.FirstContact.Address
    else
      Refer.RequestUri := Session.RemoteContact.Address;

    Refer.RequestUri.Grid := Refer.RequestUri.Grid + '-x';

    Check(not Session.Match(Refer),
          'Session mustn''t match any request whose "grid" parameter matches '
        + 'that of the GRUU that the stack sent out in creating this session');
  finally
    Refer.Free;
  end;
end;

procedure TestTIdSipSession.TestModifyBeforeFullyEstablished;
var
  Session: TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;

  try
    Session.Modify('', '');
    Fail('Failed to bail out starting a modify before session''s established');
  except
     on EIdSipTransactionUser do;
  end;
end;

procedure TestTIdSipSession.TestModifyDuringModification;
var
  Session: TIdSipSession;
begin
  Session := Self.CreateAndEstablishSession;
  Session.Modify('', '');

  try
    Session.Modify('', '');
    Fail('Failed to bail out starting a new modify while one''s in progress');
  except
    on EIdSipTransactionUser do;
  end;
end;

procedure TestTIdSipSession.TestModifyGlareInbound;
var
  Session: TIdSipSession;
begin
  // Essentially, we and Remote send INVITEs simultaneously.
  // We send ours, and it arrives after the remote end's sent us its INVITE.
  // When we receive its INVITE, we reject it with a 491 Request Pending.

  Session := Self.CreateAndEstablishSession;
  Session.Modify('', '');

  Self.MarkSentResponseCount;
  Self.ReceiveRemoteReInvite(Session);
  CheckResponseSent(Session.ClassName + ': No response sent');
  CheckEquals(SIPRequestPending,
              Dispatcher.Transport.LastResponse.StatusCode,
              Session.ClassName + ': Unexpected response');
end;

procedure TestTIdSipSession.TestModifyGlareOutbound;
const
  Body = 'random data';
var
  EventCount:  Integer;
  LatestEvent: TIdWait;
  Session:     TIdSipSession;
begin
  // Essentially, we and Remote send INVITEs simultaneously
  // We send ours and, because the remote end's sent its before ours arrives,
  // we receive its 491 Request Pending. We schedule a time to resend our
  // INVITE.

  Session := Self.CreateAndEstablishSession;

  Self.DebugTimer.TriggerAllEventsOfType(TIdSipActionsWait);
  Session.Modify(Body, PlainTextMimeType);

  Self.DebugTimer.TriggerImmediateEvents := false;
  EventCount := Self.DebugTimer.EventCount;
  Self.ReceiveResponse(SIPRequestPending);

  Self.DebugTimer.LockTimer;
  try
    Check(EventCount < Self.DebugTimer.EventCount,
          Session.ClassName + ': No timer added');

    LatestEvent := Self.DebugTimer.LastEventScheduled;

    Check(Assigned(LatestEvent),
          Session.ClassName + ': Wrong notify event');
    Self.CheckResendWaitTime(LatestEvent.DebugWaitTime,
                             Session.ClassName + ': Bad wait time (was '
                           + IntToStr(LatestEvent.DebugWaitTime) + ' milliseconds)');
  finally
    Self.DebugTimer.UnlockTimer;
  end;

  Self.MarkSentRequestCount;
  Self.DebugTimer.TriggerAllEventsOfType(TIdSipActionsWait);
  CheckRequestSent('No request sent: event not scheduled?');
  CheckEquals(MethodInvite,
              Self.LastSentRequest.Method,
              'Unexpected request');
  CheckEquals(Body,
              Self.LastSentRequest.Body,
              'Wrong message sent?');
end;

procedure TestTIdSipSession.TestModifyRejected;
var
  OldSessionDescription: String;
  OldSessionMimeType:    String;
  Session: TIdSipSession;
begin
  Session := Self.CreateAndEstablishSession;

  OldSessionDescription := Session.LocalSessionDescription;
  OldSessionMimeType    := Session.LocalMimeType;

  Session.Modify('new session desc', PlainTextMimeType);
  Self.ReceiveServiceUnavailable(Self.LastSentRequest);

  CheckEquals(OldSessionDescription,
              Session.LocalSessionDescription,
              'Session description altered');
  CheckEquals(OldSessionMimeType,
              Session.LocalMimeType,
              'Session MIME type altered');
end;

procedure TestTIdSipSession.TestModifyRejectedWithTimeout;
var
  ClassName:    String;
  Session:      TIdSipSession;
  SessionCount: Integer;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);
  ClassName := Session.ClassName;

  Session.Modify('', '');

  Self.MarkSentRequestCount;
  SessionCount := Self.Core.SessionCount;

  Self.ReceiveResponse(SIPRequestTimeout);

  CheckRequestSent(ClassName + ': No request sent');
  CheckEquals(MethodBye,
              Self.LastSentRequest.Method,
              ClassName + ': Unexpected request sent');
  Check(Self.Core.SessionCount < SessionCount,
        ClassName + ': Session not terminated');
end;

procedure TestTIdSipSession.TestModifyWaitTime;
var
  I:       Integer;
  Session: TIdSipSession;
begin
  Session := Self.CreateAction as TIdSipSession;

  // The modify wait time is random; this test does not guarantee that the wait
  // time is always correct!
  for I := 1 to 100 do
    CheckResendWaitTime(Session.ModifyWaitTime, Session.ClassName);
end;

procedure TestTIdSipSession.TestReceiveByeWithPendingRequests;
var
  Bye:      TIdSipRequest;
  ReInvite: TIdSipRequest;
  Session:  TIdSipSession;
begin
  // <---         INVITE          ---
  //  ---         200 OK          --->
  // <---          ACK            ---
  // <---         INVITE          ---
  // <---          BYE            ---
  //  ---  487 Request Terminated --- (for the re-INVITE)
  // <---          ACK            ---
  //  ---         200 OK          ---> (for the BYE)
  Session := Self.CreateAndEstablishSession;

  Self.ReceiveRemoteReInvite(Session);

  ReInvite := TIdSipRequest.Create;
  try
    ReInvite.Assign(Self.Invite);

    Self.MarkSentResponseCount;

    Bye := Self.CreateRemoteBye(Session.Dialog);
    try
      Self.ReceiveRequest(Bye);

      Check(Self.ResponseCount + 2 <= Self.SentResponseCount,
            Self.ClassName + ': No responses to both BYE and re-INVITE');

      Check(Bye.InSameDialogAs(Self.LastSentResponse),
            Self.ClassName + ': No response for BYE');
      CheckEquals(SIPOK,
                  Self.LastSentResponse.StatusCode,
                  Self.ClassName + ': Wrong response for BYE');

      Check(ReInvite.Match(Self.SecondLastSentResponse),
            Self.ClassName + ': No response for re-INVITE');
      CheckEquals(SIPRequestTerminated,
                  Self.SecondLastSentResponse.StatusCode,
                  Self.ClassName + ': Wrong response for re-INVITE');
    finally
      Bye.Free;
    end;
  finally
    ReInvite.Free;
  end;
end;

procedure TestTIdSipSession.TestReceiveInDialogReferWithNoSubscribeModule;
var
  Refer:   TIdSipRequest;
  Session: TIdSipSession;
  SubMod:  TIdSipSubscribeModule;
  Us:      TIdSipAddressHeader;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);

  if Session.IsOutboundCall then begin
    Us := Session.InitialRequest.From;
    Us.Grid := Session.InitialRequest.FirstContact.Grid;
  end
  else begin
    Us := Session.InitialRequest.ToHeader;
    Us.Grid := Self.LastSentResponse.FirstContact.Grid;
  end;

  Us.RemoveParameter(TagParam);

  SubMod := TIdSipSubscribeModule.Create(Self.Core);
  try
    Refer := SubMod.CreateRefer(Us, Self.Destination);
    try
      Refer.CallID       := Session.Dialog.ID.CallID;
      Refer.From.Tag     := Session.Dialog.ID.RemoteTag;
      Refer.ToHeader.Tag := Session.Dialog.ID.LocalTag;

      Self.MarkSentResponseCount;
      Self.ReceiveRequest(Refer);
      CheckResponseSent('No response sent');
      CheckEquals(SIPNotImplemented,
                  Self.LastSentResponse.StatusCode,
                  'Unexpected response sent');
    finally
      Refer.Free;
    end;
  finally
    SubMod.Free;
  end;
end;

procedure TestTIdSipSession.TestReceiveInDialogRefer;
var
  Refer:   TIdSipRequest;
  Session: TIdSipSession;
  SubMod:  TIdSipSubscribeModule;
  Us:      TIdSipAddressHeader;
begin
  Session := Self.CreateAction as TIdSipSession;
  Self.EstablishSession(Session);

  if Session.IsOutboundCall then begin
    Us := Session.InitialRequest.From;
    Us.Grid := Session.InitialRequest.FirstContact.Grid;
  end
  else begin
    Us := Session.InitialRequest.ToHeader;
    Us.Grid := Self.LastSentResponse.FirstContact.Grid;
  end;

  Us.RemoveParameter(TagParam);

  SubMod := Self.Core.AddModule(TIdSipSubscribeModule) as TIdSipSubscribeModule;
  Refer := SubMod.CreateRefer(Us, Self.Destination);
  try
    Refer.CallID       := Session.Dialog.ID.CallID;
    Refer.From.Tag     := Session.Dialog.ID.RemoteTag;
    Refer.ToHeader.Tag := Session.Dialog.ID.LocalTag;

    Check(Session.Match(Refer),
          'Session should match the REFER since they both use the same dialog');

    Self.ReceiveRequest(Refer);
    Check(Self.OnReferralFired,
          'Session didn''t receive the REFER');
  finally
    Refer.Free;
  end;
end;

procedure TestTIdSipSession.TestModify;
var
  Session: TIdSipSession;
begin
  Session := Self.CreateAndEstablishSession;

  Self.MarkSentRequestCount;
  Session.Modify(Self.SimpleSdp.AsString, SdpMimeType);
  CheckRequestSent(Session.ClassName + ': No INVITE sent');

  Self.ReceiveOkWithBody(Self.LastSentRequest,
                         Format(DummySDP, ['127.0.0.1']),
                         SdpMimeType);
  Check(Self.OnModifiedSessionFired,
        Session.ClassName + ': OnModifiedSession didn''t fire');

  CheckEquals(Self.SimpleSdp.AsString,
              Session.LocalSessionDescription,
              'Session.LocalSessionDescription');
  CheckEquals(SdpMimeType,
              Session.LocalMimeType,
              'Session.LocalMimeType');
  CheckEquals(Format(DummySDP, ['127.0.0.1']),
              Self.RemoteSessionDescription,
              'RemoteSessionDescription');
  CheckEquals(SdpMimeType,
              Self.MimeType,
              'MimeType');
  CheckEquals(Self.RemoteSessionDescription,
              Session.RemoteSessionDescription,
              'Session.RemoteSessionDescription');
  CheckEquals(Self.MimeType,
              Session.RemoteMimeType,
              'Session.RemoteMimeType');
end;

procedure TestTIdSipSession.TestRejectInviteWhenInboundModificationInProgress;
var
  FirstInvite: TIdSipRequest;
  Session:     TIdSipSession;
begin
  //           <established session>
  //  <---           INVITE 1           ---
  //  <---           INVITE 2           ---
  //   ---  491 Request Pending (for 2) --->
  //  <---         ACK (for 2)          ---
  //   ---        200 OK (for 1)        --->
  //  <---        ACK (for 1)           ---

  FirstInvite := TIdSipRequest.Create;
  try
    Session := Self.CreateAndEstablishSession;

    Self.ReceiveRemoteReInvite(Session);
    FirstInvite.Assign(Self.Dispatcher.Transport.LastRequest);
    Check(Self.OnModifySessionFired,
          Session.ClassName + ': OnModifySession didn''t fire');

    Self.MarkSentResponseCount;
    Self.OnModifySessionFired := false;
    Self.ReceiveRemoteReInvite(Session);
    Check(not Self.OnModifySessionFired,
          Session.ClassName + ': OnModifySession fired for a 2nd modify');
    CheckResponseSent(Session.ClassName + ': No 491 response sent');
    CheckEquals(SIPRequestPending,
                Self.LastSentResponse.StatusCode,
                Session.ClassName + ': Unexpected response to 2nd INVITE');
    Check(Self.Invite.Match(Self.LastSentResponse),
          Session.ClassName + ': Response doesn''t match 2nd INVITE');
    Self.ReceiveAck;
    Check(Session.ModificationInProgress,
          Session.ClassName + ': Modification should still be ongoing');

    Self.MarkSentResponseCount;
    Session.AcceptModify('', '');

    CheckResponseSent(Session.ClassName + ': No 200 response sent');
    CheckEquals(SIPOK,
                Self.LastSentResponse.StatusCode,
                Session.ClassName + ': Unexpected response to 1st INVITE');
    Check(FirstInvite.Match(Self.LastSentResponse),
          Session.ClassName + ': Response doesn''t match 1st INVITE');

    Self.ReceiveAckFor(FirstInvite,
                       Self.LastSentResponse);
    Check(not Session.ModificationInProgress,
          Session.ClassName + ': Modification should have finished');
  finally
    FirstInvite.Free;
  end;
end;

procedure TestTIdSipSession.TestRejectInviteWhenOutboundModificationInProgress;
var
  FirstInvite: TIdSipRequest;
  Session:     TIdSipSession;
begin
  //          <established session>
  //   ---           INVITE 1           --->
  //  <---           INVITE 2           ---
  //   ---  491 Request Pending (for 2) --->
  //  <---         ACK (for 2)          ---
  //  <---        200 OK (for 1)        ---
  //   ---        ACK (for 1)           --->

  FirstInvite := TIdSipRequest.Create;
  try
    Session := Self.CreateAndEstablishSession;
    Session.AddSessionListener(Self);

    Self.MarkSentRequestCount;
    Session.Modify('', '');
    CheckRequestSent('No modifying INVITE sent: ' + Self.FailReason);
    FirstInvite.Assign(Self.LastSentRequest);

    Self.MarkSentResponseCount;
    Self.ReceiveRemoteReInvite(Session);
    CheckResponseSent(Session.ClassName + ': No 491 response sent');
    CheckEquals(SIPRequestPending,
                Self.LastSentResponse.StatusCode,
                Session.ClassName + ': Unexpected response');
    Self.ReceiveAck;

    Self.MarkSentAckCount;
    Self.ReceiveOk(FirstInvite);
    CheckAckSent(Session.ClassName + ': No ACK sent');
  finally
    FirstInvite.Free;
  end;
end;

procedure TestTIdSipSession.TestRemodify;
const
  Body = 'random data';
var
  Session: TIdSipSession;
begin
  //      <establish session>
  //  ---       INVITE 1       --->
  // <---  491 Request Pending ---
  //  ---         ACK          --->
  //         <time passes>
  //  ---       INVITE 2       ---> (with same body as INVITE 1)

  Session := Self.CreateAndEstablishSession;
  Session.Modify(Body, PlainTextMimeType);

  // Inbound sessions can have a ModifyWaitTime of 0 - and the DebugTimer's
  // set so that it fires zero wait events immediately. Thus, for this test,
  // we switch off that behaviour.
  Self.DebugTimer.TriggerImmediateEvents := false;

  Self.ReceiveResponse(Self.LastSentRequest, SIPRequestPending);

  Self.MarkSentRequestCount;
  Session.Remodify;
  CheckRequestSent(Self.ClassName + ': No request sent');
  CheckEquals(MethodInvite,
              Self.LastSentRequest.Method,
              Self.ClassName + ': Unexpected request sent');
  CheckEquals(Body,
              Self.LastSentRequest.Body,
              Self.ClassName + ': Unexpected body in request');
end;

//******************************************************************************
//* TestTIdSipInboundSession                                                   *
//******************************************************************************
//* TestTIdSipInboundSession Public methods ************************************

procedure TestTIdSipInboundSession.SetUp;
begin
  inherited SetUp;

  Self.Core.AddUserAgentListener(Self);
  Self.Core.InviteModule.AddListener(Self);

  Self.OnEndedSessionFired    := false;
  Self.OnModifiedSessionFired := false;
  Self.SentRequestTerminated  := false;

  Self.Invite.ContentType   := SdpMimeType;
  Self.Invite.Body          := Self.SimpleSdp.AsString;
  Self.Invite.ContentLength := Length(Self.SimpleSdp.AsString);

  Self.Locator.AddA(Self.Invite.RequestUri.Host, '127.0.0.1');
end;

procedure TestTIdSipInboundSession.TearDown;
begin
  Self.Core.TerminateAllCalls;

  inherited TearDown;
end;

//* TestTIdSipInboundSession Protected methods *********************************

procedure TestTIdSipInboundSession.CheckResendWaitTime(Milliseconds: Cardinal;
                                                       const Msg: String);
begin
  Check(Milliseconds <= 2000, Msg);

  inherited CheckResendWaitTime(Milliseconds, Msg);
end;

function TestTIdSipInboundSession.CreateAction: TIdSipAction;
begin
  Self.Invite.Body := Self.RemoteDesc;

  if (Self.Invite.Body <> '') then
    Self.Invite.ContentType := Self.RemoteContentType;

  Self.Invite.ContentLength := Length(Self.RemoteDesc);

  Self.Invite.LastHop.Branch := Self.Core.NextBranch;
  Self.Invite.From.Tag       := Self.Core.NextTag;
  Self.ReceiveInvite;

  Check(Assigned(Self.Session), 'OnInboundCall not called');

  Result := Self.Session;
end;

procedure TestTIdSipInboundSession.EstablishSession(Session: TIdSipSession);
begin
  (Session as TIdSipInboundSession).AcceptCall('', '');
  Self.ReceiveAck;
end;

procedure TestTIdSipInboundSession.OnEndedSession(Session: TIdSipSession;
                                                  ErrorCode: Cardinal;
                                                  const Reason: String);
begin
  inherited OnEndedSession(Session, ErrorCode, Reason);
  Self.ActionFailed := true;

  Self.ThreadEvent.SetEvent;
end;

procedure TestTIdSipInboundSession.OnEstablishedSession(Session: TIdSipSession;
                                                        const RemoteSessionDescription: String;
                                                        const MimeType: String);
begin
  // By default, do nothing.
end;

procedure TestTIdSipInboundSession.OnInboundCall(UserAgent: TIdSipInviteModule;
                                                 Session: TIdSipInboundSession);
begin
  Self.Session := Session;
  Self.Session.AddSessionListener(Self);
end;

//* TestTIdSipInboundSession Private methods ***********************************

procedure TestTIdSipInboundSession.OnNewData(Data: TIdRTPPayload;
                                             Binding: TIdConnection);
begin
  Self.ThreadEvent.SetEvent;
end;

procedure TestTIdSipInboundSession.OnSendRequest(Request: TIdSipRequest;
                                                 Sender: TIdSipTransport;
                                                 Destination: TIdSipLocation);
begin
end;

procedure TestTIdSipInboundSession.OnSendResponse(Response: TIdSipResponse;
                                                  Sender: TIdSipTransport;
                                                  Destination: TIdSipLocation);
begin
  if (Response.StatusCode = SIPRequestTerminated) then
    Self.SentRequestTerminated := true;
end;

procedure TestTIdSipInboundSession.ReceiveAckWithBody(const SessionDesc,
                                                      ContentType: String);
var
  Ack: TIdSipRequest;
begin
  Ack := Self.Invite.AckFor(Self.LastSentResponse);
  try
    Ack.Body          := SessionDesc;
    Ack.ContentType   := ContentType;
    Ack.ContentLength := Length(Ack.Body);

    Self.ReceiveRequest(Ack);
  finally
    Ack.Free;
  end;
end;

//* TestTIdSipInboundSession Published methods ****************************************

procedure TestTIdSipInboundSession.TestAcceptCall;
var
  Answer:         String;
  AnswerMimeType: String;
begin
  Self.RemoteContentType := SdpMimeType;
  Self.RemoteDesc        := TIdSipTestResources.BasicSDP('proxy.tessier-ashpool.co.luna');
  Self.CreateAction;

  CheckEquals(Self.Dispatcher.Transport.LastRequest.FirstContact.AsString,
              Self.Session.RemoteContact.AsString,
              'RemoteContact');
  CheckEquals(Self.Dispatcher.Transport.LastRequest.From.Value,
              Self.Session.RemoteParty.Value,
              'RemoteParty');

  CheckEquals(Self.RemoteDesc,
              Self.Session.RemoteSessionDescription,
              'RemoteSessionDescription');
  CheckEquals(Self.RemoteContentType,
              Self.Session.RemoteMimeType,
              'RemoteMimeType');

  Answer         := TIdSipTestResources.BasicSDP('public.booth.org');
  AnswerMimeType := SdpMimeType;

  Self.Session.AcceptCall(Answer, AnswerMimeType);

  Check(Self.Session.DialogEstablished,
        'Dialog not established');
  CheckNotNull(Self.Session.Dialog,
               'Dialog object wasn''t created');
  CheckEquals(Answer,         Self.Session.LocalSessionDescription, 'LocalSessionDescription');
  CheckEquals(AnswerMimeType, Self.Session.LocalMimeType,           'LocalMimeType');
end;

procedure TestTIdSipInboundSession.TestAcceptCallWithGruu;
begin
  Self.UseGruu;

  Self.CreateAction;

  Self.MarkSentResponseCount;
  Self.Session.AcceptCall('', '');
  Self.CheckResponseSent('No 200 OK sent');

  // draft-ietf-sip-gruu section 8.1
  Check(Self.LastSentResponse.FirstContact.Address.HasParameter(GridParam),
        'GRUUs sent out in 200 OKs to INVITEs should have a "grid" parameter');
end;

procedure TestTIdSipInboundSession.TestAddSessionListener;
var
  L1, L2: TIdSipTestSessionListener;
begin
  Self.CreateAction;
  Self.Session.AcceptCall('', '');
  Self.ReceiveAck;

  L1 := TIdSipTestSessionListener.Create;
  try
    L2 := TIdSipTestSessionListener.Create;
    try
      Self.Session.AddSessionListener(L1);
      Self.Session.AddSessionListener(L2);

      Self.Session.Terminate;

      Check(L1.EndedSession, 'First listener not notified');
      Check(L2.EndedSession, 'Second listener not notified');

      Self.Session.RemoveSessionListener(L1);
      Self.Session.RemoveSessionListener(L2);
    finally
      L2.Free;
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipInboundSession.TestCancelAfterAccept;
var
  CancelResponse: TIdSipResponse;
  InviteResponse: TIdSipResponse;
  SessionCount:   Integer;
begin
  // <--- INVITE ---
  //  --- 200 OK --->
  // <---  ACK   ---
  // <--- CANCEL ---
  //  --- 200 OK --->
  Self.CreateAction;
  Self.Session.AcceptCall('', '');

  Self.MarkSentResponseCount;
  SessionCount  := Self.Core.SessionCount;
  Self.ReceiveCancel;

  CheckEquals(SessionCount,
              Self.Core.SessionCount,
              'Session terminated and the UA cleaned it up');
  Check(not Self.Session.IsTerminated,
        'Session terminated');
  CheckResponseSent('No response sent');

  CancelResponse := Self.LastSentResponse;
  InviteResponse := Self.Dispatcher.Transport.SecondLastResponse;

  CheckEquals(SIPOK,
              CancelResponse.StatusCode,
              'Unexpected Status-Code for CANCEL response');
  CheckEquals(MethodCancel,
              CancelResponse.CSeq.Method,
              'Unexpected CSeq method for CANCEL response');

  CheckEquals(SIPOK,
              InviteResponse.StatusCode,
              'Unexpected Status-Code for INVITE response');
  CheckEquals(MethodInvite,
              InviteResponse.CSeq.Method,
              'Unexpected CSeq method for INVITE response');
end;

procedure TestTIdSipInboundSession.TestCancelBeforeAccept;
var
  SessionCount: Integer;
begin
  // <---         INVITE         ---
  // <---         CANCEL         ---
  //  ---         200 OK         ---> (for the CANCEL)
  //  --- 487 Request Terminated ---> (for the INVITE)
  // <---           ACK          ---
  Self.CreateAction;
  SessionCount := Self.Core.SessionCount;

  Self.ReceiveCancel;

  // The UA clears out terminated sessions as soon as it finishes handling
  // a message, so the session should have terminated.
  Check(Self.Core.SessionCount < SessionCount,
        'Session didn''t terminate');

  Check(Self.OnEndedSessionFired,
        'Session didn''t notify listeners of ended session');
  CHeckEquals(NoError,
              Self.ErrorCode,
              'A remote cancel''s not an erroneous condition. ErrorCode set.');
  CheckEquals('',
              Self.Reason,
              'Reason param set');
end;

procedure TestTIdSipInboundSession.TestReceiveOutOfOrderReInvite;
var
  Response: TIdSipResponse;
begin
  // <--- INVITE (Branch = z9hG4bK776asdhds)  ---
  //  ---         100 Trying                  --->
  //  ---         180 Ringing                 --->
  //  ---         200 OK                      --->
  // <--- INVITE (Branch = z9hG4bK776asdhds1) ---
  //  ---         100 Trying                  --->
  //  ---         180 Ringing                 --->
  //  ---         500 Internal Server Error   --->

  Self.CreateAction;
  Check(Assigned(Self.Session), 'OnInboundCall not called');

  Self.Session.AcceptCall('', '');

  Self.Invite.LastHop.Branch := Self.Invite.LastHop.Branch + '1';
  Self.Invite.CSeq.SequenceNo := Self.Invite.CSeq.SequenceNo - 1;
  Self.Invite.ToHeader.Tag := Self.LastSentResponse.ToHeader.Tag;

  Self.MarkSentResponseCount;
  Self.ReceiveInvite;
  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPInternalServerError,
              Response.StatusCode,
              'Unexpected response (' + Response.StatusText + ')');
  CheckEquals(RSSIPRequestOutOfOrder,
              Response.StatusText,
              'Unexpected response, status text');
end;

procedure TestTIdSipInboundSession.TestCancelNotifiesSession;
var
  SessionCount: Integer;
begin
  Self.CreateAction;
  SessionCount := Self.Core.SessionCount;

  Self.ReceiveCancel;

  Check(Self.OnEndedSessionFired,
        'No notification of ended session');

  Check(Self.Core.SessionCount < SessionCount,
        'Session not marked as terminated');
end;

procedure TestTIdSipInboundSession.TestInviteHasNoOffer;
var
  Answer:     String;
  AnswerType: String;
  Offer:      String;
  OfferType:  String;
begin
  // <--- INVITE (with no body) ---
  //  ---  200 OK (with offer)  ---
  // <---   ACK (with answer)   ---
  Self.RemoteContentType := '';
  Self.RemoteDesc        := '';
  Self.CreateAction;

  Check(Assigned(Self.Session), 'OnInboundCall not called');

  Offer := TIdSipTestResources.BasicSDP('localhost');
  OfferType := SdpMimeType;

  Self.MarkSentResponseCount;
  Self.Session.AcceptCall(Offer, OfferType);

  CheckResponseSent('No 200 OK sent');
  CheckEquals(Offer,
              Self.LastSentResponse.Body,
              'Offer');
  CheckEquals(OfferType,
              Self.LastSentResponse.ContentType,
              'Offer MIME type');

  Answer     := TIdSipTestResources.BasicSDP('remotehost');
  AnswerType := SdpMimeType;

  Self.ReceiveAckWithBody(Answer, AnswerType);
  CheckEquals(Answer,
              Self.Session.RemoteSessionDescription,
              'RemoteSessionDescription');
  CheckEquals(AnswerType,
              Self.Session.RemoteMimeType,
              'RemoteMimeType');
end;

procedure TestTIdSipInboundSession.TestInviteHasOffer;
var
  Answer:     String;
  AnswerType: String;
begin
  // <---    INVITE (with offer)     ---
  //  ---    200 OK (with answer)    ---
  // <--- ACK (with repeat of offer) ---
  Self.RemoteContentType := SdpMimeType;
  Self.RemoteDesc        := TIdSipTestResources.BasicSDP('1.2.3.4');
  Self.CreateAction;

  Check(Assigned(Self.Session), 'OnInboundCall not called');

  Answer := TIdSipTestResources.BasicSDP('localhost');
  AnswerType := SdpMimeType;

  Self.MarkSentResponseCount;
  Self.Session.AcceptCall(Answer, AnswerType);

  CheckResponseSent('No 200 OK sent');
  CheckEquals(Answer,
              Self.LastSentResponse.Body,
              'Answer');
  CheckEquals(AnswerType,
              Self.LastSentResponse.ContentType,
              'Answer MIME type');
end;

procedure TestTIdSipInboundSession.TestIsInbound;
begin
  Self.CreateAction;
  Check(Self.Session.IsInbound,
        Self.Session.ClassName + ' not marked as inbound');
end;

procedure TestTIdSipInboundSession.TestIsOutboundCall;
begin
  Self.CreateAction;
  Check(not Self.Session.IsOutboundCall,
        'Inbound session; IsOutboundCall');
end;

procedure TestTIdSipInboundSession.TestInviteWithReplaces;
var
  Replaces: TIdSipRequest;
begin
  Self.CreateAction;

  Replaces := Self.Core.InviteModule.CreateInvite(Self.Destination, '', '');
  try
    Replaces.Replaces.CallID  := Self.Session.InitialRequest.CallID;
    Replaces.Replaces.FromTag := Self.Session.InitialRequest.From.Tag;
    Replaces.Replaces.ToTag   := Self.Session.InitialRequest.ToHeader.Tag;

    Check(Self.Session.Match(Replaces),
          'INVITE with Replaces header');
  finally
    Replaces.Free;
  end;
end;

procedure TestTIdSipInboundSession.TestLocalGruu;
var
  Session: TIdSipSession;
begin
  Self.UseGruu;

  Self.MarkSentResponseCount;
  Session := Self.CreateAndEstablishSession;
  CheckResponseSent('No 200 OK sent');

  Check(Self.LastSentResponse.FirstContact.Address.HasGrid,
        '200 OK Remote Target has no "grid" parameter');

  CheckEquals(Self.LastSentResponse.FirstContact.Grid,
              Session.LocalGruu.Grid,
              'LocalGRUU''s "grid" doesn''t match that in the 200 OK''s Contact');
  CheckEquals(Self.LastSentResponse.FirstContact.AsString,
              Session.LocalGruu.AsString,
              'LocalGRUU doesn''t match the 200 OK''s Contact');
end;

procedure TestTIdSipInboundSession.TestMethod;
begin
  CheckEquals(MethodInvite,
              TIdSipInboundSession.Method,
              'Inbound session; Method');
end;

procedure TestTIdSipInboundSession.TestNotifyListenersOfEstablishedSession;
var
  Answer:         String;
  AnswerMimeType: String;
  Listener:       TIdSipTestSessionListener;
begin
  Answer         := TIdSipTestResources.BasicSDP('public.booth.org');
  AnswerMimeType := SdpMimeType;
  Self.RemoteContentType := SdpMimeType;
  Self.RemoteDesc        := TIdSipTestResources.BasicSDP('proxy.tessier-ashpool.co.luna');
  Self.CreateAction;

  Listener := TIdSipTestSessionListener.Create;
  try
    Self.Session.AddSessionListener(Listener);
    Self.Session.AcceptCall(Answer, AnswerMimeType);

    Self.ReceiveAckWithBody(Self.RemoteDesc, Self.RemoteContentType);

    Check(Listener.EstablishedSession, 'No EstablishedSession notification');
  finally
    Self.Session.RemoveSessionListener(Listener);
    Listener.Free;
  end;
end;

procedure TestTIdSipInboundSession.TestNotifyListenersOfEstablishedSessionInviteHasNoBody;
var
  Answer:         String;
  AnswerMimeType: String;
  Listener:       TIdSipTestSessionListener;
begin
  Answer         := TIdSipTestResources.BasicSDP('public.booth.org');
  AnswerMimeType := SdpMimeType;
  Self.RemoteContentType := '';
  Self.RemoteDesc        := '';
  Self.CreateAction;

  Listener := TIdSipTestSessionListener.Create;
  try
    Self.Session.AddSessionListener(Listener);
    Self.Session.AcceptCall(Answer, AnswerMimeType);

    Self.ReceiveAckWithBody(Self.RemoteDesc, Self.RemoteContentType);

    Check(Listener.EstablishedSession, 'No EstablishedSession notification');
  finally
    Self.Session.RemoveSessionListener(Listener);
    Listener.Free;
  end;
end;

procedure TestTIdSipInboundSession.TestOkUsesGruuWhenUaDoes;
var
  Ok: TIdSipResponse;
begin
  Self.UseGruu;

  // Set up the remote stack to use GRUUs
  Self.Invite.Supported.Values.Add(ExtensionGruu);

  Self.MarkSentResponseCount;
  Self.CreateAndEstablishSession;
  Self.CheckResponseSent('No response sent');
  Ok := Self.LastSentResponse;
  Check(Ok.HasHeader(SupportedHeaderFull),
        'OK missing a Supported header');
  Check(Ok.SupportsExtension(ExtensionGruu),
        'OK''s Supported header doesn''t indicate support of GRUU');
  CheckEquals(Self.Core.Gruu.Address.Host,
              Self.LastSentResponse.FirstContact.Address.Host,
              'GRUU not used as OK''s Contact');
end;

procedure TestTIdSipInboundSession.TestInboundModifyBeforeFullyEstablished;
var
  InternalServerError: TIdSipResponse;
  Invite:              TIdSipRequest;
  Ringing:             TIdSipResponse;
begin
  //  <---           INVITE          --- (with CSeq: n INVITE)
  //   ---         100 Trying        --->
  //   ---         180 Ringing       --->
  //  <---           INVITE          --- (with CSeq: n+1 INVITE)
  //   --- 500 Internal Server Error ---> (with Retry-After)
  //  <---            ACK            ---
  //   --->         200 OK           --->
  //  <---            ACK            ---

  // We need the Ringing response to get the To tag - Ringing establishes the
  // dialog!
  Self.CreateAction;

  Ringing := Self.LastSentResponse;
  CheckEquals(SIPRinging,
              Ringing.StatusCode,
              'Sanity check');
  Check(Assigned(Self.Session), 'OnInboundCall not called');
  Check(Self.Session.DialogEstablished,
        'Session should have established a dialog - it''s sent a 180, after all');

  Self.MarkSentResponseCount;
  Invite := TIdSipRequest.Create;
  try
    Invite.Assign(Self.Session.InitialRequest);
    Invite.LastHop.Branch  := Self.Core.NextBranch;
    Invite.CSeq.SequenceNo := Self.Session.InitialRequest.CSeq.SequenceNo + 1;
    Invite.ToHeader.Tag    := Ringing.ToHeader.Tag;
    Self.ReceiveRequest(Invite);
  finally
    Invite.Free;
  end;

  CheckResponseSent('No response sent');

  InternalServerError := Self.LastSentResponse;
  CheckEquals(SIPInternalServerError,
              InternalServerError.StatusCode,
              'Unexpected response');
  Check(InternalServerError.HasHeader(RetryAfterHeader),
        'No Retry-After header');
  Check(InternalServerError.RetryAfter.NumericValue <= MaxPrematureInviteRetry,
        'Bad Retry-After value (' + IntToStr(InternalServerError.RetryAfter.NumericValue) + ')');

  Self.ReceiveAck;
end;

procedure TestTIdSipInboundSession.TestInboundModifyReceivesNoAck;
begin
  // <---    INVITE   ---
  //  --- 180 Ringing --->
  // <---     ACK     ---
  // <---    INVITE   ---
  //  ---    200 OK   --->
  //   <no ACK returned>
  //  ---     BYE     --->
  Self.CreateAction;

  Check(Assigned(Self.Session), 'OnInboundCall not called');
  Self.Session.AcceptCall('', '');
  Self.ReceiveAck;

  Self.ReceiveRemoteReInvite(Self.Session);
  Check(Self.OnModifySessionFired,
        'OnModifySession didn''t fire');
  Self.Session.AcceptModify('', '');

  Self.MarkSentRequestCount;

  // This will fire all Resend OK attempts (and possibly some other events),
  // making the inbound INVITE fail.
  Self.DebugTimer.TriggerAllEventsOfType(TIdSipActionsWait);

  CheckRequestSent('No BYE sent to terminate the dialog');

  CheckEquals(MethodBye,
              Self.LastSentRequest.Method,
              'Unexpected request sent');
end;

procedure TestTIdSipInboundSession.TestReceiveBye;
begin
  Self.CreateAction;
  Check(Assigned(Self.Session), 'OnInboundCall not called');
  Self.Session.AcceptCall('', '');

  Self.ReceiveBye(Self.Session.Dialog);

  Check(Self.OnEndedSessionFired, 'OnEndedSession didn''t fire');
end;

procedure TestTIdSipInboundSession.TestRedirectCall;
var
  Dest:         TIdSipAddressHeader;
  SentResponse: TIdSipResponse;
begin
  Self.CreateAction;
  Check(Assigned(Self.Session), 'OnInboundCall not called');
  Self.MarkSentResponseCount;

  Dest := TIdSipAddressHeader.Create;
  try
    Dest.DisplayName := 'Wintermute';
    Dest.Address.Uri := 'sip:wintermute@talking-head.tessier-ashpool.co.luna';

    Self.Session.RedirectCall(Dest);
    CheckResponseSent('No response sent');

    SentResponse := Self.LastSentResponse;
    CheckEquals(SIPMovedTemporarily,
                SentResponse.StatusCode,
                'Wrong response sent');
    Check(SentResponse.HasHeader(ContactHeaderFull),
          'No Contact header');
    CheckEquals(Dest.DisplayName,
                SentResponse.FirstContact.DisplayName,
                'Contact display name');
    CheckEquals(Dest.Address.Uri,
                SentResponse.FirstContact.Address.Uri,
                'Contact address');

    Check(Self.OnEndedSessionFired, 'OnEndedSession didn''t fire');
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipInboundSession.TestRejectCallBusy;
begin
  Self.CreateAction;
  Check(Assigned(Self.Session), 'OnInboundCall not called');

  Self.MarkSentResponseCount;
  Self.Session.RejectCallBusy;
  CheckResponseSent('No response sent');
  CheckEquals(SIPBusyHere,
              Self.LastSentResponse.StatusCode,
              'Wrong response sent');

  Check(Self.OnEndedSessionFired, 'OnEndedSession didn''t fire');
end;

procedure TestTIdSipInboundSession.TestRemoveSessionListener;
var
  L1, L2: TIdSipTestSessionListener;
begin
  Self.CreateAction;
  Check(Assigned(Self.Session), 'OnInboundCall not called');

  Self.Session.AcceptCall('', '');

  L1 := TIdSipTestSessionListener.Create;
  try
    L2 := TIdSipTestSessionListener.Create;
    try
      Self.Session.AddSessionListener(L1);
      Self.Session.AddSessionListener(L2);
      Self.Session.RemoveSessionListener(L2);

      Self.Session.Terminate;

      Check(L1.EndedSession,
            'First listener not notified');
      Check(not L2.EndedSession,
            'Second listener erroneously notified, ergo not removed');
    finally
      L2.Free
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipInboundSession.TestRing;
var
  Ringing: TIdSipResponse;
begin
  Self.MarkSentResponseCount;
  Self.CreateAction; // This sends a 180 Ringing
  Check(Assigned(Self.Session), 'OnInboundCall not called');
  CheckResponseSent('No response sent');

  Ringing := Self.LastSentResponse;
  CheckEquals(Self.Invite.CallID,
              Ringing.CallID,
              'Ringing Call-ID doesn''t match INVITE''s Call-ID');
  CheckEquals(Self.Invite.CallID,
              Self.Session.Dialog.ID.CallID,
              'Session''s Call-ID doesn''t match INVITE''s Call-ID');
  CheckEquals(Self.Invite.ToHeader.Tag,
              Self.Session.Dialog.ID.RemoteTag,
              'Session''s remote-tag doesn''t match INVITE''s To tag');
  CheckEquals(Self.Invite.From.Tag,
              Self.Session.Dialog.ID.LocalTag,
              'Session''s local-tag doesn''t match 180''s From tag');
end;

procedure TestTIdSipInboundSession.TestRingWithGruu;
begin
  Self.UseGruu;

  Self.MarkSentResponseCount;
  Self.CreateAction; // This sends a 180 Ringing
  Check(Assigned(Self.Session), 'OnInboundCall not called');
  CheckResponseSent('No response sent');

  CheckEquals(Self.Core.Gruu.Address.Host,
              Self.LastSentResponse.FirstContact.Address.Host,
              'Response didn''t use GRUU as Contact');
  Check(Self.LastSentResponse.FirstContact.Address.HasGrid,
        'Dialog-creating response (180 Ringing) has no "grid" parameter');
end;

procedure TestTIdSipInboundSession.TestSupportsExtension;
const
  ExtensionFoo = 'foo';
  Extensions   = ExtensionTargetDialog + ', ' + ExtensionFoo;
var
  Session: TIdSipSession;
begin
  Self.Invite.AddHeader(SupportedHeaderFull).Value := Extensions;
  Session := Self.CreateAndEstablishSession;
  Check(Session.SupportsExtension(ExtensionTargetDialog),
        Self.ClassName + ': '
      + ExtensionTargetDialog + ' must be supported, since both we and '
      + 'the remote party support it');
  Check(not Session.SupportsExtension(ExtensionFoo),
        Self.ClassName + ': '
      + ExtensionFoo + ' must not be supported, since only the remote '
      + 'party supports it');
end;

procedure TestTIdSipInboundSession.TestTerminate;
var
  Request:      TIdSipRequest;
  SessionCount: Integer;
begin
  Self.CreateAction;
  Check(Assigned(Self.Session), 'OnInboundCall not called');

  Self.MarkSentRequestCount;
  Self.Session.AcceptCall('', '');

  SessionCount := Self.Core.SessionCount;
  Self.Session.Terminate;

  CheckRequestSent('No BYE sent');

  Request := Self.LastSentRequest;
  Check(Request.IsBye, 'Unexpected last request');

  Check(Self.Core.SessionCount < SessionCount,
        'Session not marked as terminated');
end;

procedure TestTIdSipInboundSession.TestTerminateUnestablishedSession;
var
  Response:     TIdSipResponse;
  SessionCount: Integer;
begin
  Self.CreateAction;
  Check(Assigned(Self.Session), 'OnInboundCall not called');

  Self.MarkSentResponseCount;
  SessionCount  := Self.Core.SessionCount;

  Self.Session.Terminate;

  CheckResponseSent('no response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPRequestTerminated,
              Response.StatusCode,
              'Unexpected last response');

  Check(Self.Core.SessionCount < SessionCount,
        'Session not marked as terminated');
end;

//******************************************************************************
//* TestTIdSipOutboundSession                                                  *
//******************************************************************************
//* TestTIdSipOutboundSession Public methods ***********************************

procedure TestTIdSipOutboundSession.SetUp;
begin
  inherited SetUp;

  Self.MimeType := SdpMimeType;
  Self.SDP :='v=0'#13#10
           + 'o=franks 123456 123456 IN IP4 127.0.0.1'#13#10
           + 's=-'#13#10
           + 'c=IN IP4 127.0.0.1'#13#10
           + 'm=audio 8000 RTP/AVP 0'#13#10;

  Self.Session := Self.CreateAction as TIdSipOutboundSession;

  Self.RemoteMimeType           := '';
  Self.OnEndedSessionFired      := false;
  Self.OnModifiedSessionFired   := false;
  Self.OnProgressedSessionFired := false;
  Self.RemoteDesc               := '';

  // DNS entries for redirected domains, etc.
  Self.Locator.AddA('bar.org',   '127.0.0.1');
  Self.Locator.AddA('quaax.org', '127.0.0.1');
end;

//* TestTIdSipOutboundSession Protectedivate methods ***************************

procedure TestTIdSipOutboundSession.CheckResendWaitTime(Milliseconds: Cardinal;
                                                       const Msg: String);
begin
  Check((2100 <= Milliseconds) and (Milliseconds <= 4000), Msg);

  inherited CheckResendWaitTime(Milliseconds, Msg);
end;

function TestTIdSipOutboundSession.CreateAction: TIdSipAction;
var
  Session: TIdSipOutboundSession;
begin
  Session := Self.Core.InviteModule.Call(Self.Destination, Self.SDP, Self.MimeType);
  Session.AddSessionListener(Self);
  Session.Send;

  Result := Session;
end;

procedure TestTIdSipOutboundSession.EstablishSession(Session: TIdSipSession);
begin
  Self.ReceiveOk(Self.LastSentRequest);
end;

procedure TestTIdSipOutboundSession.OnEstablishedSession(Session: TIdSipSession;
                                                         const RemoteSessionDescription: String;
                                                         const MimeType: String);
begin
  inherited OnEstablishedSession(Session, RemoteSessionDescription, MimeType);

  Self.RemoteDesc     := RemoteSessionDescription;
  Self.RemoteMimeType := MimeType;

  Session.LocalSessionDescription := Self.LocalDescription;
  Session.LocalMimeType           := Self.LocalMimeType;
end;

procedure TestTIdSipOutboundSession.OnProgressedSession(Session: TIdSipSession;
                                                        Progress: TIdSipResponse);
begin
  inherited OnProgressedSession(Session, Progress);

  Self.OnProgressedSessionFired := true;
end;

//* TestTIdSipOutboundSession Private methods **********************************

procedure TestTIdSipOutboundSession.ReceiveBusyHere(Invite: TIdSipRequest);
var
  BusyHere: TIdSipResponse;
begin
  BusyHere := TIdSipResponse.InResponseTo(Invite,
                                          SIPBusyHere);
  try
    Self.ReceiveResponse(BusyHere);
  finally
    BusyHere.Free;
  end;
end;

procedure TestTIdSipOutboundSession.ReceiveForbidden;
var
  Response: TIdSipResponse;
begin
  Response := Self.Core.CreateResponse(Self.LastSentRequest,
                                       SIPForbidden);
  try
    Self.ReceiveResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipOutboundSession.ReceiveMovedTemporarily(Invite: TIdSipRequest;
                                                            const Contacts: array of String);
var
  I:        Integer;
  Response: TIdSipResponse;
begin
  Response := TIdSipResponse.InResponseTo(Invite,
                                          SIPMovedTemporarily);
  try
    for I := Low(Contacts) to High(Contacts) do
      Response.AddHeader(ContactHeaderFull).Value := Contacts[I];

    Self.ReceiveResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipOutboundSession.ReceiveMovedTemporarily(const Contact: String);
begin
  Self.ReceiveMovedTemporarily(Self.LastSentRequest, [Contact]);
end;

procedure TestTIdSipOutboundSession.ReceiveMovedTemporarily(const Contacts: array of String);
begin
  Self.ReceiveMovedTemporarily(Self.LastSentRequest, Contacts);
end;

procedure TestTIdSipOutboundSession.ReceiveOKWithRecordRoute;
var
  Response: TIdSipResponse;
begin
  Response := TIdSipResponse.InResponseTo(Self.LastSentRequest,
                                          SIPOK);
  try
    Response.RecordRoute.Add(RecordRouteHeader).Value := '<sip:127.0.0.1>';
    Self.ReceiveResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipOutboundSession.ReceiveRemoteDecline;
var
  Decline: TIdSipResponse;
begin
  Decline := TIdSipResponse.InResponseTo(Self.LastSentRequest,
                                         SIPDecline);
  try
    Self.ReceiveResponse(Decline);
  finally
    Decline.Free;
  end;
end;

//* TestTIdSipOutboundSession Published methods ********************************

procedure TestTIdSipOutboundSession.TestAbandonAuthentication;
var
  Action: TIdSipOutboundSession;
begin
  // This test only makes sense for OUTbound actions.
  if Self.IsInboundTest then Exit;

  Action := Self.CreateAction as TIdSipOutboundSession;

  Self.ReceiveUnauthorized(WWWAuthenticateHeader, '');

  Self.MarkSentRequestCount;
  Action.Terminate;
  Check(Action.IsTerminated,
        Self.ClassName + ': Action not terminated');
  CheckNoRequestSent(Self.ClassName + ': The Session sent a '
                   + Self.LastSentRequest.Method
                   + ' message after abandoning the authorization');

end;

procedure TestTIdSipOutboundSession.TestAck;
var
  Ack:    TIdSipRequest;
  Invite: TIdSipRequest;
begin
  Invite := TIdSipRequest.Create;
  try
    Invite.Assign(Self.LastSentRequest);

    Self.ReceiveOk(Self.LastSentRequest);

    Ack := Self.Dispatcher.Transport.LastACK;

    CheckEquals(Self.Session.Dialog.RemoteTarget,
                Ack.RequestUri,
                'Request-URI');
    CheckEquals(Invite.CSeq.SequenceNo,
                Ack.CSeq.SequenceNo,
                'CSeq sequence number');

    CheckEquals(Invite.Body,
                Ack.Body,
                'Offer');
    CheckEquals(Length(Ack.Body),
                Ack.ContentLength,
                'Content-Length');
    CheckEquals(Invite.ContentType,
                Ack.ContentType,
                'Content-Type');
    CheckEquals(Invite.ContentDisposition.Value,
                Ack.ContentDisposition.Value,
                'Content-Disposition');
    Check(Ack.ContentDisposition.IsSession,
          'Content-Disposition handling');
    CheckNotEquals(Invite.LastHop.Branch,
                   Ack.LastHop.Branch,
                   'Branch must differ - a UAS creates an ACK as an '
                 + 'in-dialog request');
  finally
    Invite.Destroy;
  end;
end;

procedure TestTIdSipOutboundSession.TestAckFromRecordRouteResponse;
var
  Ack: TIdSipRequest;
begin
  Self.ReceiveOKWithRecordRoute;
  Ack := Self.Dispatcher.Transport.LastACK;

  Check(not Ack.Route.IsEmpty, 'No Route headers');
end;

procedure TestTIdSipOutboundSession.TestAckWithAuthorization;
var
  Ack:       TIdSipRequest;
  AuthCreds: TIdSipAuthorizationHeader;
  Invite:    TIdSipRequest;
begin
  Self.MarkSentAckCount;
  Self.ReceiveUnauthorized(WWWAuthenticateHeader, '');
  CheckAckSent('No ACK sent for the challenge');

  AuthCreds := Self.CreateAuthorization(Self.Dispatcher.Transport.LastResponse);
  try
    Self.Session.Resend(AuthCreds);
  finally
    AuthCreds.Free;
  end;

  Invite := Self.LastSentRequest.Copy as TIdSipRequest;
  try
    Self.MarkSentAckCount;
    Self.ReceiveOk(Invite);
    CheckAckSent('No ACK sent for the OK: DroppedUnmatchedResponse = '
               + Self.BoolToStr(Self.DroppedUnmatchedResponse));

    Ack := Self.LastSentRequest;

    Check(Ack.HasAuthorization, 'ACK lacks Authorization header');
    CheckEquals(Invite.FirstAuthorization.FullValue,
                Ack.FirstAuthorization.FullValue,
                'Authorization');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestAckWithMultipleAuthorization;
var
  ProxyAuthCreds: TIdSipProxyAuthorizationHeader;
  UAAuthCreds:    TIdSipAuthorizationHeader;
begin
  ProxyAuthCreds := TIdSipProxyAuthorizationHeader.Create;
  try
    UAAuthCreds := TIdSipAuthorizationHeader.Create;
    try
      ProxyAuthCreds.Realm := 'alpha';

      Self.MarkSentAckCount;
      Self.ReceiveUnauthorized(ProxyAuthenticateHeader, '');
      CheckAckSent('No ACK sent to the Proxy-Authenticate challenge');

      Self.MarkSentRequestCount;
      Self.Session.Resend(ProxyAuthCreds);
      CheckRequestSent('No resend sent');
      Check(Self.LastSentRequest.HasProxyAuthorizationFor(ProxyAuthCreds.Realm),
            'Resend missing proxy authorization credentials');

      Self.MarkSentAckCount;
      Self.ReceiveUnauthorized(WWWAuthenticateHeader, '');
      CheckAckSent('No ACK sent to the WWW-Authenticate challenge');

      Self.MarkSentRequestCount;
      Self.Session.Resend(UAAuthCreds);
      CheckRequestSent('No re-resend sent');
      Check(Self.LastSentRequest.HasProxyAuthorizationFor(ProxyAuthCreds.Realm),
            'Re-resend missing proxy authorization credentials');
      Check(Self.LastSentRequest.HasAuthorizationFor(UAAuthCreds.Realm),
            'Re-resend missing UA authorization credentials');
    finally
      UAAuthCreds.Free;
    end;
  finally
    ProxyAuthCreds.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestAckWithProxyAuthorization;
var
  Ack:       TIdSipRequest;
  AuthCreds: TIdSipAuthorizationHeader;
  Invite:    TIdSipRequest;
begin
  Self.MarkSentAckCount;
  Self.ReceiveUnauthorized(ProxyAuthenticateHeader, '');
  CheckAckSent('No ACK sent for the challenge');

  AuthCreds := Self.CreateAuthorization(Self.Dispatcher.Transport.LastResponse);
  try
    Self.Session.Resend(AuthCreds);
  finally
    AuthCreds.Free;
  end;

  Invite := Self.LastSentRequest.Copy as TIdSipRequest;
  try
    Self.MarkSentAckCount;
    Self.ReceiveOk(Self.LastSentRequest);
    CheckAckSent('No ACK sent for the OK: DroppedUnmatchedResponse = '
               + Self.BoolToStr(Self.DroppedUnmatchedResponse));

    Ack := Self.LastSentRequest;

    Check(Ack.HasProxyAuthorization, 'ACK lacks Proxy-Authorization header');
    CheckEquals(Invite.FirstProxyAuthorization.FullValue,
                Ack.FirstProxyAuthorization.FullValue,
                'Proxy-Authorization');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestCall;
var
  Invite:     TIdSipRequest;
  SessCount:  Integer;
  Session:    TIdSipSession;
  TranCount:  Integer;
  Answer:     String;
  AnswerType: String;
begin
  Self.MarkSentRequestCount;
  SessCount    := Self.Core.SessionCount;
  TranCount    := Self.Dispatcher.TransactionCount;

  Self.SDP      := TIdSipTestResources.BasicSDP('proxy.tessier-ashpool.co.luna');
  Self.MimeType := SdpMimeType;

  Session := Self.CreateAction as TIdSipSession;

  CheckEquals(Self.SDP,
              Session.LocalSessionDescription,
              'LocalSessionDescription');
  CheckEquals(Self.MimeType,
              Session.LocalMimeType,
              'LocalMimeType');

  CheckEquals(Self.LastSentRequest.FirstContact.AsString,
              Session.RemoteContact.AsString,
              'RemoteContact');
  CheckEquals(Self.LastSentRequest.ToHeader.Value,
              Session.RemoteParty.Value,
              'RemoteParty');

  CheckRequestSent('no INVITE sent');
  Invite := Self.LastSentRequest;

  CheckEquals(TranCount + 1,
              Self.Dispatcher.TransactionCount,
              'no client INVITE transaction created');

  CheckEquals(SessCount + 1,
              Self.Core.SessionCount,
              'no new session created');

  Self.ReceiveRinging(Invite);

  Check(Session.IsEarly,
        'Dialog in incorrect state: should be Early');
  Check(Session.DialogEstablished,
        'Dialog not established');
  Check(not Session.Dialog.IsSecure,
        'Dialog secure when TLS not used');

  CheckEquals(Self.Dispatcher.Transport.LastResponse.CallID,
              Session.Dialog.ID.CallID,
              'Dialog''s Call-ID');
  CheckEquals(Self.Dispatcher.Transport.LastResponse.From.Tag,
              Session.Dialog.ID.LocalTag,
              'Dialog''s Local Tag');
  CheckEquals(Self.Dispatcher.Transport.LastResponse.ToHeader.Tag,
              Session.Dialog.ID.RemoteTag,
              'Dialog''s Remote Tag');

  Answer     := TIdSipTestResources.BasicSDP('sip.fried-neurons.org');
  AnswerType := SdpMimeType;
  Self.ReceiveOkWithBody(Invite, Answer, AnswerType);

  CheckEquals(Answer,
              Session.RemoteSessionDescription,
              'RemoteSessionDescription');
  CheckEquals(AnswerType,
              Session.RemoteMimeType,
              'RemoteMimeType');

  Check(not Session.IsEarly, 'Dialog in incorrect state: shouldn''t be early');
end;

procedure TestTIdSipOutboundSession.TestCallNetworkFailure;
var
  SessionCount: Cardinal;
begin
  SessionCount := Self.Core.SessionCount;
  Self.Dispatcher.Transport.FailWith := EIdConnectTimeout;

  Self.CreateAction;

  CheckEquals(SessionCount,
              Self.Core.SessionCount,
              'Core should have axed the failed session');
end;

procedure TestTIdSipOutboundSession.TestCallRemoteRefusal;
begin
  Self.ReceiveForbidden;

  Check(Self.OnEndedSessionFired, 'OnEndedSession wasn''t triggered');
end;

procedure TestTIdSipOutboundSession.TestCallSecure;
var
  Response: TIdSipResponse;
  Session:  TIdSipSession;
begin
  Self.Dispatcher.TransportType := TlsTransport;

  Self.Destination.Address.Scheme := SipsScheme;
  Session := Self.CreateAction as TIdSipSession;

  Response := Self.Core.CreateResponse(Self.LastSentRequest,
                                       SIPRinging);
  try
    Self.ReceiveResponse(Response);

    Response.StatusCode := SIPOK;
    Check(Session.Dialog.IsSecure, 'Dialog not secure when TLS used');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestCallSipsUriOverTcp;
var
  SentInvite: TIdSipRequest;
  Session:    TIdSipSession;
begin
  Self.Dispatcher.TransportType := TcpTransport;
  Self.Destination.Address.Scheme := SipsScheme;

  Self.MarkSentRequestCount;

  Session := Self.CreateAction as TIdSipSession;

  CheckRequestSent('INVITE wasn''t sent');
  SentInvite := Self.LastSentRequest;

  Self.ReceiveRinging(SentInvite);

  Check(not Session.Dialog.IsSecure, 'Dialog secure when TCP used');
end;

procedure TestTIdSipOutboundSession.TestCallSipUriOverTls;
var
  Response: TIdSipResponse;
  Session:  TIdSipSession;
begin
  Self.Dispatcher.TransportType := TcpTransport;

  Session := Self.CreateAction as TIdSipSession;

  Response := Self.Core.CreateResponse(Self.LastSentRequest,
                                       SIPOK);
  try
    Response.FirstContact.Address.Scheme := SipsScheme;
    Self.MarkSentAckCount;
    Self.ReceiveResponse(Response);
    CheckAckSent('No ACK sent: ' + Self.FailReason);

    Check(not Session.Dialog.IsSecure, 'Dialog secure when TLS used with a SIP URI');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestCallWithGruu;
var
  Invite:  TIdSipRequest;
begin
  Self.UseGruu;

  Self.MarkSentRequestCount;
  Self.CreateAction;
  CheckRequestSent('no INVITE sent');

  Invite := Self.LastSentRequest;

  // draft-ietf-sip-gruu section 8.1
  CheckEquals(Self.Core.Gruu.Address.Host,
              Invite.FirstContact.Address.Host,
              'INVITE didn''t use UA''s GRUU (' + Self.Core.Gruu.Address.AsString + ')');
  Check(Invite.FirstContact.Address.HasParameter(GridParam),
        'GRUUs sent out in INVITEs should have a "grid" parameter');
end;

procedure TestTIdSipOutboundSession.TestCallWithOffer;
var
  Answer:      String;
  ContentType: String;
begin
  //  ---     INVITE (with offer)     --->
  // <---       200 (with answer)     ---
  //  ---  ACK (with repeat of offer) --->

  Answer      := TIdSipTestResources.BasicSDP('1.1.1.1');
  ContentType := SdpMimeType;

  Check(Self.LastSentRequest.ContentDisposition.IsSession,
        'Content-Disposition');
  CheckEquals(Self.SDP,
              Self.LastSentRequest.Body,
              'INVITE offer');
  CheckEquals(SdpMimeType,
              Self.LastSentRequest.ContentType,
              'INVITE offer mime type');

  Self.MarkSentAckCount;

  Self.ReceiveOkWithBody(Self.LastSentRequest,
                         Answer,
                         ContentType);

  Check(Self.OnEstablishedSessionFired,
        'OnEstablishedSession didn''t fire');

  CheckEquals(Answer,
              Self.RemoteDesc,
              'Remote session description');
  CheckEquals(ContentType,
              Self.RemoteMimeType,
              'Remote description''s MIME type');

  CheckAckSent('No ACK sent');
  CheckEquals(Self.LastSentRequest.Body,
              Self.LastSentAck.Body,
              'ACK offer');
  CheckEquals(Self.LastSentRequest.ContentType,
              Self.LastSentAck.ContentType,
              'ACK offer MIME type');
end;

procedure TestTIdSipOutboundSession.TestCallWithoutOffer;
var
  OfferType: String;
  Offer:     String;
  Session:   TIdSipOutboundSession;
begin
  //  ---       INVITE      --->
  // <--- 200 (with offer)  ---
  //  --- ACK (with answer) --->

  OfferType := SdpMimeType;
  Offer     := TIdSipTestResources.BasicSDP('1.1.1.1');

  Self.MimeType := '';
  Self.SDP      := '';

  Session := Self.CreateAction as TIdSipOutboundSession;

  CheckEquals(Self.SDP,
              Self.LastSentRequest.Body,
              'INVITE body');
  CheckEquals(Self.MimeType,
              Self.LastSentRequest.ContentType,
              'INVITE Content-Type');

  Self.LocalDescription := TIdSipTestResources.BasicSDP('localhost');
  Self.LocalMimeType    := SdpMimeType;

  Self.MarkSentAckCount;
  Self.ReceiveOkWithBody(Self.LastSentRequest,
                         Offer,
                         OfferType);

  Check(Self.OnEstablishedSessionFired,
        'OnEstablishedSession didn''t fire');
  CheckEquals(Offer,
              Self.RemoteDesc,
              'Remote description');
  CheckEquals(OfferType,
              Self.RemoteMimeType,
              'Remote description''s MIME type');

  CheckAckSent('No ACK sent');
  CheckEquals(Session.LocalSessionDescription,
              Self.LastSentAck.Body,
              'ACK answer');
  CheckEquals(Session.LocalMimeType,
              Self.LastSentAck.ContentType,
              'ACK answer MIME type');
end;

procedure TestTIdSipOutboundSession.TestCancelReceiveInviteOkBeforeCancelOk;
var
  Cancel: TIdSipRequest;
  Invite: TIdSipRequest;
begin
  //  ---          INVITE         --->
  // <---        100 Trying       ---
  //  ---          CANCEL         --->
  // <--- 200 OK (for the INVITE) ---
  //  ---           ACK           --->
  // <--- 200 OK (for the CANCEL) ---
  //  ---           BYE           --->
  // <---   200 OK (for the BYE)  ---

  Invite := TIdSipRequest.Create;
  try
    Cancel := TIdSipRequest.Create;
    try
      Invite.Assign(Self.LastSentRequest);
      Self.ReceiveTrying(Invite);

      Self.Session.Cancel;
      Cancel.Assign(Self.LastSentRequest);

      Self.MarkSentRequestCount;
      Self.ReceiveOk(Invite);
      Self.ReceiveOk(Cancel);

      Check(Self.OnEndedSessionFired,
            'Listeners not notified of end of session');
    finally
      Cancel.Free;
    end;
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestCircularRedirect;
begin
  //  ---   INVITE (original)   --->
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->
  //  --- INVITE (redirect #1)  --->
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->
  //  --- INVITE (redirect #2)  --->
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->
  //  --- INVITE (redirect #1)  ---> again!
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->

  Self.ReceiveMovedTemporarily('sip:foo@bar.org');
  Self.ReceiveMovedTemporarily('sip:bar@bar.org');

  Self.MarkSentRequestCount;
  Self.ReceiveMovedTemporarily('sip:foo@bar.org');
  CheckNoRequestSent('The session accepted the run-around');
end;

procedure TestTIdSipOutboundSession.TestDialogNotEstablishedOnTryingResponse;
var
  SentInvite: TIdSipRequest;
  Session:    TIdSipSession;
begin
  Self.MarkSentRequestCount;

  Session := Self.CreateAction as TIdSipSession;
  Check(not Session.DialogEstablished, 'Brand new session');

  CheckRequestSent('The INVITE wasn''t sent');
  SentInvite := Self.LastSentRequest;

  Self.ReceiveTryingWithNoToTag(SentInvite);
  Check(not Session.DialogEstablished,
        'Dialog established after receiving a 100 Trying');

  Self.ReceiveRinging(SentInvite);
  Check(Session.DialogEstablished,
        'Dialog not established after receiving a 180 Ringing');
end;

procedure TestTIdSipOutboundSession.TestDoubleRedirect;
begin
  //  ---   INVITE (original)   --->
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->
  //  --- INVITE (redirect #1)  --->
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->
  //  --- INVITE (redirect #2)  --->
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->

  Self.MarkSentRequestCount;
  Self.ReceiveMovedTemporarily('sip:foo@bar.org');
  CheckRequestSent('No redirected INVITE #1 sent: ' + Self.FailReason);
  CheckEquals('sip:foo@bar.org',
              Self.LastSentRequest.RequestUri.Uri,
              'Request-URI of redirect #1');

  Self.MarkSentRequestCount;
  Self.ReceiveMovedTemporarily('sip:baz@quaax.org');
  CheckRequestSent('No redirected INVITE #2 sent: ' + Self.FailReason);
  CheckEquals('sip:baz@quaax.org',
              Self.LastSentRequest.RequestUri.Uri,
              'Request-URI of redirect #2');
end;

procedure TestTIdSipOutboundSession.TestEmptyTargetSetMeansTerminate;
begin
  Self.ReceiveMovedTemporarily('sip:foo@bar.org');
  Self.ReceiveForbidden;
  Check(Self.OnEndedSessionFired, 'Session didn''t end: ' + Self.FailReason);
end;

procedure TestTIdSipOutboundSession.TestEstablishedSessionSetsInitialRequestToTag;
begin
  Self.ReceiveRinging(Self.LastSentRequest);
  CheckEquals(Self.Dispatcher.Transport.LastResponse.ToHeader.Tag,
              Self.Session.InitialRequest.ToHeader.Tag,
              'Session.InitialRequest''s To tag not set');
end;

procedure TestTIdSipOutboundSession.TestGlobalFailureEndsSession;
var
  SessionCount: Integer;
begin
  SessionCount := Self.Core.SessionCount;

  Self.ReceiveRemoteDecline;

  Check(Self.OnEndedSessionFired,
        'No notification of ended session');

  Check(Self.Core.SessionCount < SessionCount,
        'Session not torn down because of a global failure');
end;

procedure TestTIdSipOutboundSession.TestHangUp;
begin
  Self.ReceiveOk(Self.LastSentRequest);

  Self.MarkSentRequestCount;
  Self.Session.Terminate;

  CheckRequestSent('No BYE sent');
  CheckEquals(MethodBye,
              Self.LastSentRequest.Method,
              'TU didn''t sent a BYE');
  Self.ReceiveOk(Self.LastSentRequest);
end;

procedure TestTIdSipOutboundSession.TestIsOutboundCall;
begin
  Check(Self.Session.IsOutboundCall,
        'Outbound session; IsOutboundCall');
end;

procedure TestTIdSipOutboundSession.TestMethod;
begin
  CheckEquals(MethodInvite,
              TIdSipOutboundSession.Method,
              'Outbound session; Method');
end;

procedure TestTIdSipOutboundSession.TestModifyUsesAuthentication;
var
  AuthCreds: TIdSipAuthorizationHeader;
  Invite:    TIdSipRequest;
  Modify:    TIdSipRequest;
begin
  // n, n+1, n+2, ..., n+m is the sequence of branch IDs generated by Self.Core.
  //  ---      INVITE      ---> (with branch n)
  // <--- 401 Unauthorized ---  (with branch n)
  //  ---      INVITE      ---> (with branch n+1)
  // <---      200 OK      ---  (with branch n+1)
  //  ---        ACK       ---> (with branch n+1)
  //  ---      INVITE      ---> (modify) (with branch n+2)

  Invite := TIdSipRequest.Create;
  try
    Self.ReceiveUnauthorized(WWWAuthenticateHeader, '');

    Self.MarkSentRequestCount;

    AuthCreds := Self.CreateAuthorization(Self.Dispatcher.Transport.LastResponse);
    try
      Self.Session.Resend(AuthCreds);
    finally
      AuthCreds.Free;
    end;

    CheckRequestSent('No resend of INVITE with Authorization');
    Invite.Assign(Self.LastSentRequest);
    Check(Invite.HasAuthorization,
          'Resend INVITE has no Authorization header');

    Self.ReceiveOk(Self.LastSentRequest);
    Check(not Self.Session.IsEarly,
          'The UA didn''t update the InviteAction''s InitialRequest as a'
             + ' result of the authentication challenge.');

    Self.Session.Modify('', '');

    Modify := Self.LastSentRequest;
    Check(Modify.HasAuthorization,
          'No Authorization header');
    CheckEquals(Invite.FirstAuthorization.Value,
                Modify.FirstAuthorization.Value,
                'Authorization header');
    CheckEquals(Invite.CSeq.SequenceNo + 1,
                Modify.CSeq.SequenceNo,
                'Unexpected sequence number in the modify');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestNetworkFailuresLookLikeSessionFailures;
begin
  Self.Dispatcher.Transport.FailWith := Exception;
  Self.ReceiveOk(Self.LastSentRequest);

  Check(Assigned(Self.ActionParam), 'OnNetworkFailure didn''t fire');
  Check(Self.ActionParam = Self.Session,
        'Session must signal the network error as _its_ error, not the '
      + 'Invite''s');
end;

procedure TestTIdSipOutboundSession.TestReceive1xxNotifiesListeners;
begin
  Self.ReceiveTrying(Self.LastSentRequest);

  Check(Self.OnProgressedSessionFired,
        'Listeners not notified of progress for initial INVITE');

  Self.EstablishSession(Self.Session);

  Self.OnProgressedSessionFired := false;
  Self.Session.Modify('', '');

  Self.ReceiveTrying(Self.LastSentRequest);

  Check(Self.OnProgressedSessionFired,
        'Listeners not notified of progress for modify INVITE');
end;

procedure TestTIdSipOutboundSession.TestReceive2xxSendsAck;
var
  Ack:    TIdSipRequest;
  Invite: TIdSipRequest;
  Ok:     TIdSipResponse;
begin
  Ok := Self.CreateRemoteOk(Self.LastSentRequest);
  try
    Self.MarkSentAckCount;
    Self.ReceiveResponse(Ok);

    CheckAckSent('Original ACK');

    Self.MarkSentAckCount;
    Self.ReceiveResponse(Ok);
    CheckAckSent('Retransmission');

    Ack := Self.LastSentAck;
    CheckEquals(MethodAck, Ack.Method, 'Unexpected method');
    Invite := Self.Session.InitialRequest;
    CheckEquals(Invite.CSeq.SequenceNo,
                Ack.CSeq.SequenceNo,
                'CSeq numerical portion');
    CheckEquals(MethodAck,
                Ack.CSeq.Method,
                'CSeq method');
  finally
    Ok.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestReceive3xxSendsNewInvite;
const
  NewAddress = 'sip:foo@bar.org';
var
  OriginalInvite: TIdSipRequest;
begin
  OriginalInvite := TIdSipRequest.Create;
  try
    OriginalInvite.Assign(Self.LastSentRequest);

    Self.MarkSentRequestCount;
    Self.ReceiveMovedPermanently(NewAddress);

    CheckRequestSent('Session didn''t send a new INVITE: ' + Self.FailReason);
  finally
    OriginalInvite.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestReceive3xxWithOneContact;
var
  Contact:     String;
  InviteCount: Integer;
  RequestUri:  TIdSipUri;
begin
  //  ---         INVITE        --->
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->
  //  ---         INVITE        --->
  // <---     403 Forbidden     ---
  //  ---          ACK          --->

  Contact      := 'sip:foo@bar.org';
  InviteCount  := Self.Core.CountOf(MethodInvite);
  Self.MarkSentRequestCount;
  Self.ReceiveMovedTemporarily(Contact);

  CheckRequestSent('No new INVITE sent: ' + Self.FailReason);
  CheckEquals(InviteCount,
              Self.Core.CountOf(MethodInvite),
              'The Core should have one new INVITE and have destroyed one old one');

  RequestUri := Self.LastSentRequest.RequestUri;
  CheckEquals(Contact,
              RequestUri.Uri,
              'Request-URI');

  Self.ReceiveForbidden;
  Check(Self.Core.CountOf(MethodInvite) < InviteCount,
        'The Core didn''t destroy the second INVITE');
  Check(Self.OnEndedSessionFired,
        'Listeners not notified of failed call');
end;

procedure TestTIdSipOutboundSession.TestReceive3xxWithNoContacts;
var
  Redirect: TIdSipResponse;
begin
  Redirect := TIdSipResponse.InResponseTo(Self.LastSentRequest,
                                          SIPMovedPermanently);
  try
    Redirect.ToHeader.Tag := Self.Core.NextTag;
    Self.ReceiveResponse(Redirect);

    Check(Self.OnEndedSessionFired,
          'Session didn''t end despite a redirect with no Contact headers');
    CheckEquals(RedirectWithNoContacts, Self.ErrorCode, 'Stack reports wrong error code');
    CheckNotEquals('',
                   Self.Reason,
                   'Reason param not set');
  finally
    Redirect.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestReceiveFailureResponseAfterSessionEstablished;
var
  Invite: TIdSipRequest;
begin
  //  ---          INVITE         --->
  // <---          200 OK         ---
  //  ---           ACK           --->
  // <--- 503 Service Unavailable --- (in response to the INVITE!)

  // This situation should never arise: the remote end's sending a failure
  // response to a request it has already accepted. Still, I've seen it happen
  // once before...

  Invite := TIdSipRequest.Create;
  try
    Invite.Assign(Self.LastSentRequest);

    Self.MarkSentAckCount;
    Self.ReceiveOk(Invite);
    CheckAckSent('No ACK sent');

    Self.ReceiveServiceUnavailable(Invite);

    Check(not Self.Session.IsTerminated,
          'The Session received the response: the Transaction-User layer didn''t '
        + 'drop the message, or the Session Matched the request');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestReceiveFailureResponseNotifiesOnce;
var
  L:       TIdSipTestSessionListenerEndedCounter;
  Session: TIdSipOutboundSession;
begin
  Session := Self.Core.InviteModule.Call(Self.Destination, Self.SDP, SdpMimeType);
  L := TIdSipTestSessionListenerEndedCounter.Create;
  try
    Session.AddSessionListener(L);
    Session.Send;

    Self.ReceiveResponse(SIPDecline);

    CheckEquals(1, L.EndedNotificationCount, 'Not notified only once');
  finally
    L.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestReceiveFailureSetsReason;
begin
  Self.CreateAction;
  Self.ReceiveBusyHere(Self.LastSentRequest);

  Check(Self.OnEndedSessionFired,
        'OnEndedSession didn''t fire');
  CheckNotEquals('',
                 Self.Reason,
                 'Reason param not set');
end;

procedure TestTIdSipOutboundSession.TestReceiveFinalResponseSendsAck;
var
  I: Integer;
begin
  // Of course this works. That's because the transaction sends the ACK for a
  // non-2xx final response.
  for I := SIPRedirectionResponseClass to SIPGlobalFailureResponseClass do begin
    Self.MarkSentAckCount;

    Self.CreateAction;

    Self.ReceiveResponse(I*100);
    CheckAckSent('Session didn''t send an ACK to a final response, '
               + Self.LastSentResponse.Description);
  end;
end;

procedure TestTIdSipOutboundSession.TestRedirectAndAccept;
var
  Contact:     String;
  InviteCount: Integer;
  RequestUri:  TIdSipUri;
begin
  //  ---         INVITE        --->
  // <--- 302 Moved Temporarily ---
  //  ---          ACK          --->
  //  ---         INVITE        --->
  // <---         200 OK        ---
  //  ---          ACK          --->

  Contact      := 'sip:foo@bar.org';
  InviteCount  := Self.Core.CountOf(MethodInvite);
  Self.MarkSentRequestCount;
  Self.ReceiveMovedTemporarily(Contact);

  CheckRequestSent('No new INVITE sent: ' + Self.FailReason);
  CheckEquals(InviteCount,
              Self.Core.CountOf(MethodInvite),
              'The Core should have one new INVITE and have destroyed one old one');

  RequestUri := Self.LastSentRequest.RequestUri;
  CheckEquals(Contact,
              RequestUri.Uri,
              'Request-URI');

  Self.ReceiveOk(Self.LastSentRequest);

  Check(Self.OnEstablishedSessionFired,
        'Listeners not notified of a successful call');
end;

procedure TestTIdSipOutboundSession.TestRedirectMultipleOks;
const
  FirstInvite    = 0;
  FirstRedirect  = 1;
  SecondRedirect = 2;
  ThirdRedirect  = 3;
  Bye            = 4;
  Cancel         = 5;
var
  Contacts: array of String;
begin
  //                               Request number:
  //  ---       INVITE        ---> #0
  // <---   302 (foo,bar,baz) ---
  //  ---        ACK          --->
  //  ---     INVITE(foo)     ---> #1
  //  ---     INVITE(bar)     ---> #2
  //  ---     INVITE(baz)     ---> #3
  // <---      200 (bar)      ---
  //  ---        ACK          --->
  // <---      200 (foo)      ---
  //  ---        ACK          --->
  //  ---        BYE          ---> #4 (because we've already established a session)
  // <---    200 (foo,BYE)    ---
  // <---      100 (baz)      ---
  //  ---       CANCEL        ---> #5
  // <---  200 (baz,CANCEL)   ---

  SetLength(Contacts, 3);
  Contacts[0] := 'sip:foo@bar.org';
  Contacts[1] := 'sip:bar@bar.org';
  Contacts[2] := 'sip:baz@bar.org';

  Self.MarkSentRequestCount;
  Self.ReceiveMovedTemporarily(Contacts);

  // ARG! Why do they make Length return an INTEGER? And WHY Abs() too?
  CheckEquals(Self.RequestCount + Cardinal(Length(Contacts)),
              Self.Dispatcher.Transport.SentRequestCount,
              'Session didn''t attempt to contact all Contacts: ' + Self.FailReason);

  Self.MarkSentRequestCount;
  Self.ReceiveOkFrom(Self.SentRequestAt(SecondRedirect), Contacts[1]);
  Self.ReceiveOkFrom(Self.SentRequestAt(FirstRedirect), Contacts[0]);
  Self.ReceiveTryingFrom(Self.SentRequestAt(ThirdRedirect), Contacts[2]);

  // We expect a BYE in response to the 1st UA's 2xx and a CANCEL to the 2nd
  // UA's 1xx.

  // ARG! Why do they make Length return an INTEGER? And WHY Abs() too?
  CheckEquals(Self.RequestCount + Cardinal(Length(Contacts) - 1),
              Self.Dispatcher.Transport.SentRequestCount,
              'Session didn''t try to kill all but one of the redirected INVITEs');

  CheckRequestSent('We expect the session to send _something_');
  CheckEquals(MethodBye,
              Self.SentRequestAt(Bye).Method,
              'Unexpected first request sent');
  CheckEquals(Contacts[0],
              Self.SentRequestAt(Bye).RequestUri.Uri,
              'Unexpected target for the first BYE');
  CheckEquals(MethodCancel,
              Self.SentRequestAt(Cancel).Method,
              'Unexpected second request sent');
  CheckEquals(Contacts[2],
              Self.SentRequestAt(Cancel).RequestUri.Uri,
              'Unexpected target for the second BYE');
end;

procedure TestTIdSipOutboundSession.TestRedirectNoMoreTargets;
var
  Contacts: array of String;
begin
  //                                           Request number:
  //  ---              INVITE             ---> #0
  // <---          302 (foo,bar)          ---
  //  ---               ACK               --->
  //  ---           INVITE (foo)          ---> #1
  //  ---           INVITE (bar)          ---> #2
  // <--- 302 (from foo, referencing bar) ---
  // <--- 302 (from bar, referencing foo) ---
  //  ---          ACK (to foo)           --->
  //  ---          ACK (to bar)           --->

  SetLength(Contacts, 2);
  Contacts[0] := 'sip:foo@bar.org';
  Contacts[1] := 'sip:bar@bar.org';

  Self.ReceiveMovedTemporarily(Contacts);

  Check(Self.SentRequestCount >= 3,
        'Not enough requests sent: 1 + 2 INVITEs: ' + Self.FailReason);

  Self.ReceiveMovedTemporarily(Self.SentRequestAt(1), Contacts[1]);
  Self.ReceiveMovedTemporarily(Self.SentRequestAt(2), Contacts[0]);

  Check(Self.OnEndedSessionFired,
        'Session didn''t notify listeners of ended session');
  CheckEquals(RedirectWithNoMoreTargets, Self.ErrorCode,
              'Session reported wrong error code for no more redirect targets');
  CheckNotEquals('',
                 Self.Reason,
                 'Reason param not set');
end;

procedure TestTIdSipOutboundSession.TestRedirectWithMultipleContacts;
var
  Contacts: array of String;
begin
  SetLength(Contacts, 2);
  Contacts[0] := 'sip:foo@bar.org';
  Contacts[1] := 'sip:bar@bar.org';

  Self.MarkSentRequestCount;

  Self.ReceiveMovedTemporarily(Contacts);

  // ARG! Why do they make Length return an INTEGER? And WHY Abs() too?
  CheckEquals(Self.RequestCount + Cardinal(Length(Contacts)),
              Self.Dispatcher.Transport.SentRequestCount,
              'Session didn''t attempt to contact all Contacts: ' + Self.FailReason);
end;

procedure TestTIdSipOutboundSession.TestRedirectWithNoSuccess;
var
  Contacts: array of String;
begin
  //                             Request number:
  //  ---       INVITE      ---> #0
  // <---   302 (foo,bar)   ---
  //  ---        ACK        --->
  //  ---    INVITE (foo)   ---> #1
  //  ---    INVITE (bar)   ---> #2
  // <---     486 (foo)     ---
  // <---     486 (bar)     ---
  //  ---    ACK (to foo)   --->
  //  ---    ACK (to bar)   --->

  SetLength(Contacts, 2);
  Contacts[0] := 'sip:foo@bar.org';
  Contacts[1] := 'sip:bar@bar.org';

  Self.ReceiveMovedTemporarily(Contacts);

  Check(Self.SentRequestCount >= 3,
        'Not enough requests sent: 1 + 2 INVITEs: ' + Self.FailReason);

  Self.ReceiveBusyHere(Self.SentRequestAt(1));
  Self.ReceiveBusyHere(Self.SentRequestAt(2));

  Check(Self.OnEndedSessionFired,
        'Session didn''t notify listeners of ended session');
  CheckEquals(RedirectWithNoSuccess, Self.ErrorCode,
              'Session reported wrong error code for no successful rings');
  CheckNotEquals('',
                 Self.Reason,
                 'Reason param not set');
end;

procedure TestTIdSipOutboundSession.TestSendSetsInitialRequest;
var
  Session: TIdSipAction;
begin
  Session := Self.CreateAction;
  Check(Session.InitialRequest.Equals(Self.LastSentRequest),
        'Sending the session didn''t set the session''s InitialRequest');

  // I don't know why, but if you leave these lines out,
  // TestTerminateDuringRedirect will (sometimes) fail in its TearDown.
  Self.ReceiveTrying(Self.LastSentRequest);
  Session.Terminate;
end;

procedure TestTIdSipOutboundSession.TestSendWithGruu;
var
  Session: TIdSipSession;
begin
  Self.UseGruu;

  Self.MarkSentRequestCount;
  Session := Self.CreateAndEstablishSession;
  CheckRequestSent('No INVITE sent');

  CheckEquals(Self.Core.Gruu.Address.Host,
              Session.LocalGruu.Address.Host,
              'LocalGruu not set');
  Check(Session.LocalGruu.Address.HasGrid,
        'Local GRUU doesn''t have a "grid" parameter');
end;

procedure TestTIdSipOutboundSession.TestSupportsExtension;
var
  MissingExtension: String;
  OK:               TIdSipResponse;
  Session:          TIdSipOutboundSession;
begin
  // For the ACK's Request-URI
  Self.Locator.AddA('tessier-ashpool.co.luna', '127.0.0.1');

  CheckNotEquals('',
                 Self.Module.AllowedExtensions,
                 Self.ClassName
               + ': Sanity check: our InviteModule should support at least one '
               + 'extension');

  Session := Self.Module.Call(Self.Destination, '', '');
  Session.Send;
  Check(Session.InitialRequest.HasHeader(SupportedHeaderFull),
        Self.ClassName
      + ': Sanity check: the InviteModule MUST insert a Supported header');

  OK := TIdSipResponse.InResponseTo(Session.InitialRequest, SIPOK, Self.Invite.FirstContact);
  try
    OK.Supported.Value := Self.Module.AllowedExtensions;

    MissingExtension := OK.Supported.Values[0];
    OK.Supported.Values.Delete(0);
    Self.ReceiveResponse(OK);

    Check(Session.SupportsExtension(OK.Supported.Values[0]),
          Self.ClassName
        + ': Session MUST support ' + OK.Supported.Values[0] + ' since both we '
        + 'and the remote party do');

    Check(not Session.SupportsExtension(MissingExtension),
          Self.ClassName
        + ': Session MUST NOT support ' + OK.Supported.Values[0] + ' since '
        + 'only we do');
  finally
    OK.Free;
  end;
end;

procedure TestTIdSipOutboundSession.TestTerminateDuringRedirect;
var
  Contacts: array of String;
  I:        Integer;
begin
  //                             Request count
  //  ---       INVITE      ---> #0
  // <---   302 (foo,bar)   ---
  //  ---        ACK        --->
  //  ---    INVITE (foo)   ---> #1
  //  ---    INVITE (bar)   ---> #2
  // <---     100 (foo)     --- (we receive 100s so the InviteActions will send CANCELs immediately)
  // <---     100 (bar)     ---
  // <Terminate the connection attempt>
  //  ---    CANCEL (foo)   ---> #3
  // <--- 200 (foo, CANCEL) ---
  //  ---    CANCEL (bar)   ---> #4
  // <--- 200 (bar, CANCEL) ---

  SetLength(Contacts, 2);
  Contacts[0] := 'sip:foo@bar.org';
  Contacts[1] := 'sip:bar@bar.org';

  Self.ReceiveMovedTemporarily(Contacts);

  Check(Self.SentRequestCount >= 3,
        'Not enough requests sent: 1 + 2 INVITEs: ' + Self.FailReason);

  Self.ReceiveTrying(Self.SentRequestAt(1));
  Self.ReceiveTrying(Self.SentRequestAt(2));

  Self.MarkSentRequestCount;
  Self.Session.Terminate;

  // ARG! Why do they make Length return an INTEGER? And WHY Abs() too?
  CheckEquals(Self.RequestCount + Cardinal(Length(Contacts)),
              Self.Dispatcher.Transport.SentRequestCount,
              'Session didn''t attempt to terminate all INVITEs');

  Check(Self.SentRequestCount >= 5,
        'Not enough requests sent: 1 + 2 INVITEs, 2 CANCELs');

  for I := 0 to 1 do begin
    CheckEquals(Contacts[I],
                Self.SentRequestAt(I + 3).RequestUri.Uri,
                'CANCEL to ' + Contacts[I]);
    CheckEquals(MethodCancel,
                Self.SentRequestAt(I + 3).Method,
                'Request method to ' + Contacts[I]);
  end;
end;

procedure TestTIdSipOutboundSession.TestTerminateEstablishedSession;
var
  SessionCount: Integer;
begin
  Self.ReceiveOk(Self.LastSentRequest);

  Self.MarkSentRequestCount;
  SessionCount := Self.Core.SessionCount;
  Self.Session.Terminate;

  CheckRequestSent('No request sent');
  CheckEquals(MethodBye,
              Self.LastSentRequest.Method,
              'Session didn''t terminate with a BYE');

  Check(Self.Core.SessionCount < SessionCount,
        'Session not marked as terminated');
end;

procedure TestTIdSipOutboundSession.TestTerminateNetworkFailure;
var
  SessionCount: Integer;
begin
  Self.ReceiveOk(Self.LastSentRequest);

  Self.Dispatcher.Transport.FailWith := EIdConnectTimeout;

  SessionCount := Self.Core.SessionCount;
  Self.Session.Terminate;

  Check(Self.Core.SessionCount < SessionCount,
        'Session not marked as terminated');
  CheckEquals(MethodBye,
              Self.Dispatcher.Transport.LastRequest.Method,
              'Last request we attempted to send');
end;

procedure TestTIdSipOutboundSession.TestTerminateUnestablishedSession;
var
  Invite:            TIdSipRequest;
  Request:           TIdSipRequest;
  RequestTerminated: TIdSipResponse;
  SessionCount:      Integer;
begin
  // When you Terminate a Session, the Session should attempt to CANCEL its
  // initial INVITE (if it hasn't yet received a final response).

  Self.MarkSentRequestCount;

  Invite := TIdSipRequest.Create;
  try
    Invite.Assign(Self.LastSentRequest);

    // We don't actually send CANCELs when we've not received a provisional
    // response.
    Self.ReceiveRinging(Invite);

    RequestTerminated := TIdSipResponse.InResponseTo(Invite, SIPRequestTerminated);
    try
      RequestTerminated.ToHeader.Tag := Self.Session.Dialog.ID.RemoteTag;

      SessionCount := Self.Core.SessionCount;
      Self.Session.Terminate;

      CheckRequestSent('no CANCEL sent');

      Request := Self.LastSentRequest;
      CheckEquals(MethodCancel,
                  Request.Method,
                  'Session didn''t terminate with a CANCEL');

      Self.ReceiveResponse(RequestTerminated);

      Check(Self.Core.SessionCount < SessionCount,
            'Session not marked as terminated');
    finally
      RequestTerminated.Free;
    end;
  finally
    Invite.Free;
  end;
end;

//******************************************************************************
//* TestSessionReplacer                                                        *
//******************************************************************************
//* TestSessionReplacer Public methods *****************************************

procedure TestSessionReplacer.SetUp;
begin
  inherited SetUp;

  Self.Alice          := Self.CreateTransferringUA(Self.DebugTimer,
                                                   'sip:alice@127.0.0.1');
  Self.AlicesNewPhone := Self.CreateTransferringUA(Self.DebugTimer,
                                                   'sip:alice@127.0.0.2');
  Self.Bob            := Self.CreateTransferringUA(Self.DebugTimer,
                                                   'sip:bob@127.0.0.3');
  Self.ParkPlace      := Self.CreateTransferringUA(Self.DebugTimer,
                                                   'sip:parkingplace@127.0.0.4');
end;

procedure TestSessionReplacer.TearDown;
begin
  Self.ParkPlace.Free;
  Self.Bob.Free;
  Self.Alice.Free;

  inherited TearDown;
end;

//* TestSessionReplacer Private methods ****************************************

function TestSessionReplacer.CreateTransferringUA(Timer: TIdTimerQueue;
                                                  const Address: String): TIdSipUserAgent;
var
  SubMod: TIdSipSubscribeModule;
begin
  Result := Self.CreateUserAgent(Timer, Address);
  Result.InviteModule.AddListener(Self);

  (Result.Dispatcher as TIdSipMockTransactionDispatcher).Transport.Address := Result.Contact.Address.Host;
  (Result.Dispatcher as TIdSipMockTransactionDispatcher).Transport.Port    := Result.Contact.Address.Port;

  SubMod := Result.AddModule(TIdSipSubscribeModule) as TIdSipSubscribeModule;
  SubMod.AddPackage(TIdSipReferPackage);
  SubMod.AddListener(Self);
end;

procedure TestSessionReplacer.OnDroppedUnmatchedMessage(UserAgent: TIdSipAbstractCore;
                                                        Message: TIdSipMessage;
                                                        Receiver: TIdSipTransport);
begin
  // It'd be nice to fail here, but three UAs all use this same procedure; for
  // each response, two of the three will drop the response as unmatched.
end;

procedure TestSessionReplacer.OnInboundCall(UserAgent: TIdSipInviteModule;
                                            Session: TIdSipInboundSession);
begin
  Self.InboundCall := Session;
  Self.ReceivingUA := UserAgent.UserAgent;
end;

procedure TestSessionReplacer.OnRenewedSubscription(UserAgent: TIdSipAbstractCore;
                                                    Subscription: TIdSipOutboundSubscription);
begin
end;

procedure TestSessionReplacer.OnSubscriptionRequest(UserAgent: TIdSipAbstractCore;
                                                    Subscription: TIdSipInboundSubscription);
begin
  Self.ReceivingUA := UserAgent as TIdSipUserAgent;
  Self.Refer       := Subscription;
end;

function TestSessionReplacer.SubscribeModuleOf(UA: TIdSipUserAgent): TIdSipSubscribeModule;
begin
  Result := UA.ModuleFor(MethodSubscribe) as TIdSipSubscribeModule;
end;

//* TestSessionReplacer Published methods **************************************

procedure TestSessionReplacer.TestSessionReplacer;
var
  AlicesReferToBob: TIdSipOutboundReferral;
  AlicesReplace:    TIdSipOutboundSession;
  BobsCallToAlice:  TIdSipOutboundSession;
  BobsCallToPP:     TIdSipOutboundSession;
begin
// cf. RFC 3891, section 1 for the inspiration for this test:
//        Alice          Alice                             Parking
//        phone1         phone2            Bob               Place
//        |               |                 |                   |
//        |<===============================>|                   |
//        |               |                 |                   |
//        |        Alice transfers Bob to Parking Place         |
//        |               |                 |                   |
//        |------------REFER/200----------->|                   |
//        |<--NOTIFY/200 (trying)-----------|--INVITE/200/ACK-->|
//        |<--NOTIFY/200 (success)----------|<=================>|
//        |------------BYE/200------------->|                   |
//        |               |                 |                   |
//        |               |                 |                   |
//        |  Alice later retrieves call from another phone      |
//        |               |                 |                   |
//        |               |-INV w/Replaces->|                   |
//        |               |<--200-----------|                   |
//        |               |---ACK---------->|----BYE/200------->|
//        |               |<===============>|                   |
//        |               |                 |                   |

  // Bob calls Alice; Alice answers
  BobsCallToAlice := Bob.InviteModule.Call(Alice.From, '', '');
  BobsCallToAlice.Send;
  Check(Assigned(Self.InboundCall) and (Self.ReceivingUA = Self.Alice),
        'Alice''s UA isn''t ringing');
  Self.InboundCall.AcceptCall('', '');

  // Alice refers Bob to the Parking Place
  AlicesReferToBob := Self.SubscribeModuleOf(Alice).Refer(Self.Bob.Contact,
                                                          Self.ParkPlace.From);
  AlicesReferToBob.Send;
  Check(Assigned(Self.Refer) and (Self.ReceivingUA = Self.Bob),
        'Bob''s UA didn''t receive the REFER');
  CheckEquals(TIdSipInboundReferral.ClassName,
              Self.Refer.ClassName,
              'Unexpected subscription request');

  // and Bob calls the Parking Place, which automatically answers.
  BobsCallToPP := Self.Bob.InviteModule.Call(Self.ParkPlace.From, '', '');
  BobsCallToPP.Send;
  Check(Assigned(Self.InboundCall) and (Self.ReceivingUA = Self.ParkPlace),
        'The Parking Place UA isn''t ringing');
  Self.InboundCall.AcceptCall('', '');
  (Self.Refer as TIdSipInboundReferral).ReferenceSucceeded;

  // Now Alice retrieves the call from the Parking Place
  AlicesReplace := Self.AlicesNewPhone.InviteModule.ReplaceCall(BobsCallToPP.InitialRequest,
                                                                Self.Bob.From,
                                                                '',
                                                                '');
  AlicesReplace.Send;
  Check(Assigned(Self.InboundCall) and (Self.ReceivingUA = Self.Bob),
        'Bob''s UA isn''t ringing');
end;

//******************************************************************************
//* TestTIdSipInviteModuleOnInboundCallMethod                                  *
//******************************************************************************
//* TestTIdSipInviteModuleOnInboundCallMethod Public methods *******************

procedure TestTIdSipInviteModuleOnInboundCallMethod.SetUp;
begin
  inherited SetUp;

  Self.Invite   := TIdSipTestResources.CreateBasicRequest;
  Self.Dispatcher.MockLocator.AddA(Self.Invite.LastHop.SentBy, '127.0.0.1');

  Self.Listener := TIdSipTestInviteModuleListener.Create;
  Self.Session  := TIdSipInboundSession.CreateInbound(Self.UA, Self.Invite, false);

  Self.Method := TIdSipInviteModuleInboundCallMethod.Create;
  Self.Method.Session   := Self.Session;
  Self.Method.UserAgent := Self.UA.InviteModule;
end;

procedure TestTIdSipInviteModuleOnInboundCallMethod.TearDown;
begin
  Self.Method.Free;
  Self.Session.Free; // The UA doesn't own this action - we created it ourselves.
  Self.Listener.Free;
  Self.Invite.Free;

 inherited TearDown;
end;

//* TestTIdSipInviteModuleOnInboundCallMethod Published methods ****************

procedure TestTIdSipInviteModuleOnInboundCallMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.InboundCall,
        'Listener not notified');
  Check(Self.Session = Self.Listener.SessionParam,
        'Session param');
  Check(Self.UA.InviteModule = Self.Listener.UserAgentParam,
        'UserAgent param');
end;

//******************************************************************************
//* TInviteMethodTestCase                                                      *
//******************************************************************************
//* TInviteMethodTestCase Public methods ***************************************

procedure TInviteMethodTestCase.SetUp;
var
  Nowhere: TIdSipAddressHeader;
begin
  inherited SetUp;

  Nowhere := TIdSipAddressHeader.Create;
  try
    Self.Invite := TIdSipOutboundInvite.Create(Self.UA);
  finally
    Nowhere.Free;
  end;

  Self.Listener := TIdSipTestInviteListener.Create;
end;

procedure TInviteMethodTestCase.TearDown;
begin
  Self.Listener.Free;
  Self.Invite.Free;

  inherited TearDown;
end;

//******************************************************************************
//* TestTIdSipInviteCallProgressMethod                                         *
//******************************************************************************
//* TestTIdSipInviteCallProgressMethod Public methods **************************

procedure TestTIdSipInviteCallProgressMethod.SetUp;
begin
  inherited SetUp;

  Self.Method := TIdSipInviteCallProgressMethod.Create;
  Self.Method.Invite   := Self.Invite;
  Self.Method.Response := Self.Response;
end;

procedure TestTIdSipInviteCallProgressMethod.TearDown;
begin
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipInviteCallProgressMethod Published methods ***********************

procedure TestTIdSipInviteCallProgressMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.CallProgress,
        'Listener not notified');
  Check(Self.Invite = Self.Listener.InviteAgentParam,
        'InviteAgent param');
  Check(Self.Response = Self.Listener.ResponseParam,
        'Response param');
end;

//******************************************************************************
//* TestTIdSipInboundInviteFailureMethod                                       *
//******************************************************************************
//* TestTIdSipInboundInviteFailureMethod Public methods ************************

procedure TestTIdSipInboundInviteFailureMethod.SetUp;
begin
  inherited SetUp;

  Self.Invite := TIdSipTestResources.CreateBasicRequest;

  Self.Method := TIdSipInboundInviteFailureMethod.Create;
  Self.Method.Invite := TIdSipInboundInvite.CreateInbound(Self.UA, Self.Invite, false);
end;

procedure TestTIdSipInboundInviteFailureMethod.TearDown;
begin
  Self.Method.Invite.Free;
  Self.Method.Free;
  Self.Invite.Free;

  inherited TearDown;
end;

//* TestTIdSipInboundInviteFailureMethod Published methods *********************

procedure TestTIdSipInboundInviteFailureMethod.TestRun;
var
  Listener: TIdSipTestInboundInviteListener;
begin
  Listener := TIdSipTestInboundInviteListener.Create;
  try
    Self.Method.Run(Listener);

    Check(Listener.Failed, 'Listener not notified');
    Check(Self.Method.Invite = Listener.InviteAgentParam,
          'InviteAgent param');
  finally
    Listener.Free;
  end;
end;

//******************************************************************************
//* TestTIdSipInviteDialogEstablishedMethod                                    *
//******************************************************************************
//* TestTIdSipInviteDialogEstablishedMethod Public methods *********************

procedure TestTIdSipInviteDialogEstablishedMethod.SetUp;
var
  Nowhere: TIdSipAddressHeader;
begin
  inherited SetUp;

  Self.Method := TIdSipInviteDialogEstablishedMethod.Create;

  Nowhere := TIdSipAddressHeader.Create;
  try
    Self.Method.Invite := TIdSipOutboundInvite.Create(Self.UA);
    Self.Method.Dialog := TIdSipDialog.Create;
  finally
    Nowhere.Free;
  end;
end;

procedure TestTIdSipInviteDialogEstablishedMethod.TearDown;
begin
  Self.Method.Invite.Free;
  Self.Method.Dialog.Free;
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipInviteDialogEstablishedMethod Published methods ******************

procedure TestTIdSipInviteDialogEstablishedMethod.TestRun;
var
  Listener: TIdSipTestInviteListener;
begin
  Listener := TIdSipTestInviteListener.Create;
  try
    Self.Method.Run(Listener);

    Check(Listener.DialogEstablished, 'Listener not notified');
    Check(Self.Method.Invite = Listener.InviteAgentParam,
          'InviteAgent param');
    Check(Self.Method.Response = Listener.ResponseParam,
          'Response param');
  finally
    Listener.Free;
  end;
end;

//******************************************************************************
//* TestInviteMethod                                                           *
//******************************************************************************
//* TestInviteMethod Public methods ********************************************

procedure TestInviteMethod.SetUp;

begin
  inherited SetUp;

  Self.Invite   := Self.UA.AddOutboundAction(TIdSipOutboundInitialInvite) as TIdSipOutboundInitialInvite;
  Self.Listener := TIdSipTestInviteListener.Create;
end;

procedure TestInviteMethod.TearDown;
begin
  Self.Listener.Free;
  // Self.UA owns Self.Invite!

  inherited TearDown;
end;

//******************************************************************************
//* TestTIdSipInviteFailureMethod                                              *
//******************************************************************************
//* TestTIdSipInviteFailureMethod Public methods *******************************

procedure TestTIdSipInviteFailureMethod.SetUp;
begin
  inherited SetUp;

  Self.Method := TIdSipInviteFailureMethod.Create;

  Self.Method.Invite   := Self.Invite;
  Self.Method.Reason   := 'none';
  Self.Method.Response := Self.Response;
end;

procedure TestTIdSipInviteFailureMethod.TearDown;
begin
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipInviteFailureMethod Published methods ****************************

procedure TestTIdSipInviteFailureMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.Failure, 'Listener not notified');
  Check(Self.Method.Invite = Self.Listener.InviteAgentParam,
        'InviteAgent param');
  Check(Self.Method.Response = Self.Listener.ResponseParam,
        'Response param');
  CheckEquals(Self.Method.Reason,
              Self.Listener.ReasonParam,
              'Reason param');
end;

//******************************************************************************
//* TestTIdSipInviteRedirectMethod                                             *
//******************************************************************************
//* TestTIdSipInviteRedirectMethod Public methods ******************************

procedure TestTIdSipInviteRedirectMethod.SetUp;
begin
  inherited SetUp;

  Self.Method := TIdSipInviteRedirectMethod.Create;

  Self.Method.Invite   := Self.Invite;
  Self.Method.Response := Self.Response;
end;

procedure TestTIdSipInviteRedirectMethod.TearDown;
begin
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipInviteRedirectMethod Published methods ***************************

procedure TestTIdSipInviteRedirectMethod.Run;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.Redirect, 'Listener not notified');
  Check(Self.Method.Invite = Self.Listener.InviteAgentParam,
        'Invite param');
  Check(Self.Method.Response = Self.Listener.ResponseParam,
        'Response param');
end;

//******************************************************************************
//* TestTIdSipInviteSuccessMethod                                              *
//******************************************************************************
//* TestTIdSipInviteSuccessMethod Public methods *******************************

procedure TestTIdSipInviteSuccessMethod.SetUp;
begin
  inherited SetUp;

  Self.Method := TIdSipInviteSuccessMethod.Create;

  Self.Method.Invite   := Self.Invite;
  Self.Method.Response := Self.Response;
end;

procedure TestTIdSipInviteSuccessMethod.TearDown;
begin
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipInviteSuccessMethod Published methods ****************************

procedure TestTIdSipInviteSuccessMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.Success, 'Listener not notified');
  Check(Self.Method.Invite = Self.Listener.InviteAgentParam,
        'InviteAgent param');
  Check(Self.Method.Response = Self.Listener.ResponseParam,
        'Response param');
end;

//******************************************************************************
//* TestSessionMethod                                                          *
//******************************************************************************
//* TestSessionMethod Public methods *******************************************

procedure TestSessionMethod.SetUp;
begin
  inherited SetUp;

  Self.Listener := TIdSipTestSessionListener.Create;
  Self.Session  := TIdSipOutboundSession.Create(Self.UA);
end;

procedure TestSessionMethod.TearDown;
begin
  Self.Session.Free;
  Self.Listener.Free;

  inherited TearDown;
end;

//******************************************************************************
//* TestTIdSipEndedSessionMethod                                               *
//******************************************************************************
//* TestTIdSipEndedSessionMethod Public methods ********************************

procedure TestTIdSipEndedSessionMethod.SetUp;
const
  ArbValue = 42;
begin
  inherited SetUp;

  Self.Method := TIdSipEndedSessionMethod.Create;

  Self.Method.Session   := Self.Session;
  Self.Method.ErrorCode := ArbValue;
  Self.Method.Reason    := 'arbitrary reason';
end;

procedure TestTIdSipEndedSessionMethod.TearDown;
begin
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipEndedSessionMethod Published methods *****************************

procedure TestTIdSipEndedSessionMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Method.Session = Self.Listener.SessionParam,
        'Session param');
  CheckEquals(Self.Method.ErrorCode,
              Self.Listener.ErrorCodeParam,
              'ErrorCode param');
  CheckEquals(Self.Method.Reason,
              Self.Listener.ReasonParam,
              'Reason param');
end;

//******************************************************************************
//* TestTIdSipEstablishedSessionMethod                                         *
//******************************************************************************
//* TestTIdSipEstablishedSessionMethod Public methods **************************

procedure TestTIdSipEstablishedSessionMethod.SetUp;
begin
  inherited SetUp;

  Self.Method := TIdSipEstablishedSessionMethod.Create;

  Self.Method.RemoteSessionDescription := 'I describe a session''s media';
  Self.Method.MimeType                 := 'text/plain';
  Self.Method.Session                  := Self.Session;
end;

procedure TestTIdSipEstablishedSessionMethod.TearDown;
begin
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipEstablishedSessionMethod Published methods ***********************

procedure TestTIdSipEstablishedSessionMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Method.Session = Self.Listener.SessionParam,
        'Session param');
  CheckEquals(Self.Method.MimeType,
              Self.Listener.MimeType,
              'MimeType param');
  CheckEquals(Self.Method.RemoteSessionDescription,
              Self.Listener.RemoteSessionDescription,
              'RemoteSessionDescription param');
end;

//******************************************************************************
//* TestTIdSipModifiedSessionMethod                                            *
//******************************************************************************
//* TestTIdSipModifiedSessionMethod Public methods *****************************

procedure TestTIdSipModifiedSessionMethod.SetUp;
begin
  inherited SetUp;

  Self.Answer := TIdSipResponse.Create;

  Self.Method := TIdSipModifiedSessionMethod.Create;

  Self.Method.Session := Self.Session;
  Self.Method.Answer  := Self.Answer;
end;

procedure TestTIdSipModifiedSessionMethod.TearDown;
begin
  Self.Method.Free;
  Self.Answer.Free;

  inherited TearDown;
end;

//* TestTIdSipModifiedSessionMethod Published methods **************************

procedure TestTIdSipModifiedSessionMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Method.Answer = Self.Listener.AnswerParam,
        'Answer param');
  Check(Self.Method.Session = Self.Listener.SessionParam,
        'Session param');
end;

//******************************************************************************
//* TestTIdSipSessionModifySessionMethod                                       *
//******************************************************************************
//* TestTIdSipSessionModifySessionMethod Public methods ************************

procedure TestTIdSipSessionModifySessionMethod.SetUp;
var
  Invite: TIdSipRequest;
begin
  inherited SetUp;

  Self.Method := TIdSipSessionModifySessionMethod.Create;

  Invite := TIdSipTestResources.CreateBasicRequest;
  try
    Self.Session := Self.UA.InviteModule.Call(Invite.ToHeader, '', '');

    Self.Method.RemoteSessionDescription := Invite.Body;
    Self.Method.Session                  := Self.Session;
    Self.Method.MimeType                 := Invite.ContentType;
  finally
    Invite.Free;
  end;
end;

//* TestTIdSipSessionModifySessionMethod Published methods *********************

procedure TestTIdSipSessionModifySessionMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Method.Session = Self.Listener.SessionParam,
        'Modify param');
  CheckEquals(Self.Method.MimeType,
              Self.Listener.MimeType,
              'MimeType');
  CheckEquals(Self.Method.RemoteSessionDescription,
              Self.Listener.RemoteSessionDescription,
              'RemoteSessionDescription');
end;

//******************************************************************************
//* TestTIdSipProgressedSessionMethod                                          *
//******************************************************************************
//* TestTIdSipProgressedSessionMethod Public methods ***************************

procedure TestTIdSipProgressedSessionMethod.SetUp;
begin
  inherited SetUp;

  Self.Progress := TIdSipResponse.Create;

  Self.Method := TIdSipProgressedSessionMethod.Create;

  Self.Method.Progress := Self.Progress;
  Self.Method.Session  := Self.Session;
end;

procedure TestTIdSipProgressedSessionMethod.TearDown;
begin
  Self.Method.Free;
  Self.Progress.Free;

  inherited TearDown;
end;

//* TestTIdSipProgressedSessionMethod Published methods ************************

procedure TestTIdSipProgressedSessionMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.ProgressedSession,
        'Listener not notified');
  Check(Self.Method.Progress = Self.Listener.ProgressParam,
        'Progress param');
  Check(Self.Method.Session = Self.Listener.SessionParam,
        'Session param');
end;

//******************************************************************************
//* TestTIdSipSessionReferralMethod
//******************************************************************************
//* TestTIdSipSessionReferralMethod Public methods *****************************

procedure TestTIdSipSessionReferralMethod.SetUp;
begin
  inherited SetUp;

  Self.Method := TIdSipSessionReferralMethod.Create;
  Self.Refer  :=  TIdSipRequest.Create;

  Self.Method.Refer   := Self.Refer;
  Self.Method.Session := Self.Session;
end;

procedure TestTIdSipSessionReferralMethod.TearDown;
begin
  Self.Refer.Free;
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipSessionReferralMethod Published methods **************************

procedure TestTIdSipSessionReferralMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.Referral,
        'Listener not notified');
  Check(Self.Method.Refer = Self.Listener.ReferParam,
        'Refer param');
  Check(Self.Method.Session = Self.Listener.SessionParam,
        'Session param');
end;

initialization
  RegisterTest('Invite Module tests', Suite);
end.