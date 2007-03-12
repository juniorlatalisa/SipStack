unit TestStringDictionary;

interface

uses
  StringDictionary, TestFramework;

type
  TestTStringDictionary = class(TTestCase)
  private
    D: TStringDictionary;

    procedure CheckNegative(KeyA, KeyB: TKeyValuePair; Msg: String);
    procedure CheckPositive(KeyA, KeyB: TKeyValuePair; Msg: String);
    procedure CheckZero(KeyA, KeyB: TKeyValuePair; Msg: String);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAddAndCount;
    procedure TestClear;
    procedure TestFind;
    procedure TestHasKey;
    procedure TestRemove;
    procedure TestSort;
    procedure TestSortAndFindUseConsistentSorting;
  end;

implementation

uses
  SysUtils;

function Suite: ITestSuite;
begin
  Result := TTestSuite.Create('StringDictionary unit tests');
  Result.AddTest(TestTStringDictionary.Suite);
end;

//******************************************************************************
//* TestTStringDictionary                                                      *
//******************************************************************************
//* TestTStringDictionary Public methods ***************************************

procedure TestTStringDictionary.SetUp;
begin
  inherited SetUp;

  Self.D := TStringDictionary.Create;
end;

procedure TestTStringDictionary.TearDown;
begin
  Self.D.Free;

  inherited TearDown;
end;

//* TestTStringDictionary Private methods **************************************

procedure TestTStringDictionary.CheckNegative(KeyA, KeyB: TKeyValuePair; Msg: String);
var
  RC: Integer;
begin
  RC := TKeyValuePairSort(KeyA, KeyB);
  Check(RC < 0, Msg + '(' + IntToStr(RC) + ')');
end;

procedure TestTStringDictionary.CheckPositive(KeyA, KeyB: TKeyValuePair; Msg: String);
var
  RC: Integer;
begin
  RC := TKeyValuePairSort(KeyA, KeyB);
  Check(RC > 0, Msg + '(' + IntToStr(RC) + ')');
end;

procedure TestTStringDictionary.CheckZero(KeyA, KeyB: TKeyValuePair; Msg: String);
var
  RC: Integer;
begin
  RC := TKeyValuePairSort(KeyA, KeyB);
  CheckEquals(0, RC, Msg);
end;

//* TestTStringDictionary Published methods ************************************

procedure TestTStringDictionary.TestAddAndCount;
begin
  CheckEquals(0, Self.D.Count, 'Initially empty');

  Self.D.Add('foo', 'bar');
  CheckEquals(1, Self.D.Count, 'After one add');

  Self.D.Add('foo', 'baz');
  CheckEquals(1, Self.D.Count, 'Key already present');

  Self.D.Add('quaax', 'bar');
  CheckEquals(2, Self.D.Count, 'Two Adds (of unique keys)');
end;

procedure TestTStringDictionary.TestClear;
begin
  Self.D.Add('foo', '1');
  Self.D.Add('bar', '2');
  Self.D.Add('baz', '3');
  Self.D.Add('quaax', '4');

  Self.D.Clear;

  CheckEquals(0, Self.D.Count, 'Dictionary not cleared');
end;

procedure TestTStringDictionary.TestFind;
begin
  Self.D.Add('foo', '1');
  Self.D.Add('bar', '2');
  Self.D.Add('baz', '3');
  Self.D.Add('quaax', '4');

  CheckEquals('1', Self.D.Find('foo'),   '"foo"''s value');
  CheckEquals('2', Self.D.Find('bar'),   '"bar"''s value');
  CheckEquals('3', Self.D.Find('baz'),   '"baz"''s value');
  CheckEquals('4', Self.D.Find('quaax'), '"quaax"''s value');

  CheckEquals('', Self.D.Find('not in the dictionary'), 'Unknown key must return the empty string');
end;

procedure TestTStringDictionary.TestHasKey;
begin
  Check(not Self.D.HasKey('foo'), '"foo" present in an empty list?');

  Self.D.Add('foo', 'bar');
  Check(Self.D.HasKey('foo'), '"foo" not added');

  Self.D.Remove('foo');
  Check(not Self.D.HasKey('foo'), '"foo" not removed');
end;

procedure TestTStringDictionary.TestRemove;
begin
  Self.D.Add('foo', 'bar');
  Self.D.Remove('foo');

  Check(not Self.D.HasKey('foo'), '"foo" not removed');
end;

procedure TestTStringDictionary.TestSort;
var
  KeyA, KeyB: TKeyValuePair;
begin
  KeyA := TKeyValuePair.Create('foo', '1');
  try
    KeyB := TKeyValuePair.Create('foo', '1');
    try
      CheckEquals(0, TKeyValuePairSort(KeyA, KeyB), '(foo 1) = (foo 1)');

      KeyB.Value := '2';
      CheckNegative(KeyA, KeyB, '(foo 1) < (foo 2)');
      CheckPositive(KeyB, KeyA, '(foo 2) > (foo 1)');

      KeyA.Value := '1';
      KeyB.Key   := 'bar';
      CheckPositive(KeyA, KeyB, '(foo 1) > (bar 1)');
      CheckNegative(KeyB, KeyA, '(bar 1) < (foo 1)');

      KeyB.Value := '2';
      CheckPositive(KeyA, KeyB, '(foo 1) > (bar 2)');
      CheckNegative(KeyB, KeyA, '(bar 2) < (foo 1)');
    finally
      KeyB.Free;
    end;
  finally
    KeyA.Free;
  end;
end;

procedure TestTStringDictionary.TestSortAndFindUseConsistentSorting;
begin
  Self.D.Add('Call-ID',  'Call-ID');
  Self.D.Add('i',        'Call-ID');
  Check(Self.D.HasKey('i'), 'Has key "i"');
  Self.D.Add('Priority', 'Priority');
  Check(Self.D.HasKey('i'), 'Still has key "i"');
end;

initialization
  RegisterTest('Dictionary tests', Suite);
end.