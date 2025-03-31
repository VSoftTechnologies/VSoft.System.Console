unit System.Console.InternalTypes;

interface

uses
  System.Types,
  System.Classes,
  System.SysUtils,
  System.Console.Types;

type
  //don't add interface here, otherwise we will need to make methods virtual;
  TConsoleImplementation = class
  protected
    procedure RaiseUnsupported(const methodName : string);
    function PlatformName : string;virtual;abstract;
    //protected as only called from this class
    procedure WriteString(const value : string);virtual;abstract;
    procedure SetTempColors(foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);virtual;abstract;
    procedure RestoreColors;virtual;abstract;
  public
    function OpenStandardInput  : TStream;virtual;abstract;
    function OpenStandardOutput : TStream;virtual;abstract;
    function OpenStandardError  : TStream;virtual;abstract;

    function GetOrCreateReader  : TTextReader;virtual;abstract;

    function GetBackgroundColor: TConsoleColor; virtual;abstract;
    procedure SetBackgroundColor(value: TConsoleColor); virtual;abstract;

    function GetForegroundColor: TConsoleColor; virtual;abstract;
    procedure SetForegroundColor(value: TConsoleColor); virtual;abstract;

    procedure SetColors(foreground : TConsoleColor; background : TConsoleColor);virtual;abstract;
    procedure ResetColors;virtual;abstract;

    function GetBufferWidth : integer;virtual;abstract;
    procedure SetBufferWidth(value : integer);virtual;abstract;

    function GetBufferHeight : integer;virtual;abstract;
    procedure SetBufferHeight(value : integer);virtual;abstract;

    procedure SetBufferSize(width : integer; height : integer);virtual;abstract;

    function GetCursorPosition: TPoint;virtual;abstract;
    procedure SetCursorPosition(x : integer; y : integer);virtual;abstract;


    function GetCursorLeft : integer; virtual;abstract;
    procedure SetCursorLeft(value: integer); virtual;abstract;

    function GetCursorTop : integer; virtual;abstract;
    procedure SetCursorTop(value : integer); virtual;abstract;

    function GetCursorSize : integer;virtual;abstract;
    procedure SetCursorSize(value : integer); virtual;abstract;

    function GetCursorVisible : boolean;virtual;abstract;
    procedure SetCursorVisible(value : boolean); virtual;abstract;


    function GetTitle : string;virtual;abstract;
    procedure SetTitle(const value : string);virtual;abstract;


    function GetIsErrorRedirected : boolean;virtual;abstract;
    function GetIsInputRedirected : boolean;virtual;abstract;
    function GetIsOutputRedirected: boolean;virtual;abstract;

    function GetConsoleOutputEncoding : TEncoding;virtual;abstract;
    procedure SetConsoleOutputEncoding(const value : TEncoding);virtual;abstract;
    function GetConsoleInputEncoding : TEncoding;virtual;abstract;
    procedure SetConsoleInputEncoding(const value : TEncoding);virtual;abstract;


    function GetWindowSize : TSize;virtual;abstract;
    procedure SetWindowSize(const width : integer; height : integer);virtual;abstract;

    function GetWindowPosition : TPoint;virtual;abstract;
    procedure SetWindowPosition(Left, Top: Integer);virtual;abstract;


    function GetLargestWindowHeight : integer;virtual;abstract;
    function GetLargestWindowWidth : integer;virtual;abstract;

    function GetCancelKeyPress : TConsoleCancelEventHandler;virtual;abstract;
    procedure SetCancelKeyPress(value : TConsoleCancelEventHandler);virtual;abstract;


    procedure Beep(frequency : Cardinal; duration: Cardinal); overload; virtual;abstract;
    procedure Beep; overload; virtual;abstract;

    procedure Clear;virtual;abstract;

    procedure MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop: Integer); overload; virtual;
    procedure MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop: Integer; sourceChar: Char; sourceForeColor, sourceBackColor: TConsoleColor); overload; virtual;

    function GetKeyAvailable : boolean;virtual;abstract;
    function ReadKey(intercept: boolean) : TConsoleKeyInfo;virtual;abstract;

    function GetCapsLock: boolean; virtual;abstract;
    function GetNumLock : boolean; virtual;abstract;
    function GetTreatControlCAsInput: boolean;virtual;abstract;
    procedure SetTreatControlCAsInput(value : boolean);virtual;abstract;

    //these all call into WriteString
    procedure Write(value : boolean);overload;
    procedure Write(c : Char);overload;virtual;
    procedure Write(chars : TArray<Char>);overload;
    procedure Write(const s : string);overload;
    procedure Write(const obj : TObject);overload;
    procedure Write<T>(const value : T);overload;

    procedure WriteLine;overload;
    procedure WriteLine(value : boolean);overload;
    procedure WriteLine(c : Char);overload;
    procedure WriteLine(const obj : TObject);overload;
    procedure WriteLine(const s : string);overload;
    procedure WriteLine<T>(const value : T);overload;

  end;

  TConsoleImplFactory = class
  public
    class function CreateConsole : TConsoleImplementation;static;
  end;

  TFileAccess = (
        // Specifies read access to the file. Data can be read from the file and
        // the file pointer can be moved. Combine with WRITE for read-write access.
        Read = 1,

        // Specifies write access to the file. Data can be written to the file and
        // the file pointer can be moved. Combine with READ for read-write access.
        Write = 2
  );


const
    // Unlike many other buffer sizes throughout .NET, which often only affect performance, this buffer size has a
    // functional impact on interactive console apps, where the size of the buffer passed to ReadFile/Console impacts
    // how many characters the cmd window will allow to be typed as part of a single line. It also does affect perf,
    // in particular when input is redirected and data may be consumed from a larger source. This 4K default size is the
    // same as is currently used by most other environments/languages tried.
    ReadBufferSize = 4096;
    // There's no visible functional impact to the write buffer size, and as we auto flush on every write,
    // there's little benefit to having a large buffer.  So we use a smaller buffer size to reduce working set.
    const WriteBufferSize = 256;


implementation

uses
  System.TypInfo,
  System.Rtti,
  System.Console,
  {$IFDEF MSWINDOWS}
  System.Console.Windows;
  {$ELSEIF MACOS }
  System.Console.Posix;
  {$ELSEIF LINUX }
  System.Console.Posix;
  {$ELSE}
    Invalid platform
  {$IFEND}

procedure TConsoleImplementation.Write(const s: string);
begin
  WriteString(s);
end;

procedure TConsoleImplementation.Write(value: boolean);
begin
  WriteString(BoolToStr(value, true));
end;

procedure TConsoleImplementation.MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop: Integer; sourceChar: Char; sourceForeColor, sourceBackColor: TConsoleColor);
begin
  RaiseUnsupported('MoveBufferArea');
end;

procedure TConsoleImplementation.MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop: Integer);
begin
  RaiseUnsupported('MoveBufferArea');
end;

procedure TConsoleImplementation.RaiseUnsupported(const methodName : string);
begin
  if Console.RaiseUnsupported then
    raise EUnsupportedException.Create('Method [' + methodName + '] is not supported on ' + PlatformName );

end;

procedure TConsoleImplementation.Write(const obj: TObject);
begin
  if obj <> nil then
    WriteString(obj.ToString);
end;

procedure TConsoleImplementation.Write<T>(const value: T);
var
  thevalue : Tvalue;
  arrayElement : Tvalue;
  arrayLength : integer;
  i : integer;
begin
  //Tvalue.Make<T> only in 10.4 and does this anyway
  Tvalue.Make(@value, System.TypeInfo(T), thevalue);
  if thevalue.IsArray then
  begin
    arrayLength := thevalue.GetArrayLength;
    if arrayLength = 0 then
      exit;

    for i := 0 to arrayLength -1 do
    begin
      arrayElement := thevalue.GetArrayElement(i);
      Write(arrayElement.ToString);
    end;
    exit;
  end;

  if thevalue.IsObject and (thevalue.TypeInfo.Kind <> tkInterface) then
  begin
    Write(thevalue.AsObject);
    exit;
  end;

  if thevalue.TypeInfo.Kind = tkRecord then
  begin
    Write('Write<T> - unsupported type : record');
    exit;
  end;
  Write(thevalue.ToString);
end;

procedure TConsoleImplementation.Write(chars : TArray<Char>);
begin
  WriteString(string(chars));
end;

procedure TConsoleImplementation.WriteLine(const s: string);
begin
  WriteString(s + sLineBreak);
end;

procedure TConsoleImplementation.WriteLine(const obj: TObject);
begin
  WriteString(obj.ToString + sLineBreak);
end;

procedure TConsoleImplementation.WriteLine<T>(const value: T);
var
  thevalue : Tvalue;
  arrayElement : Tvalue;
  arrayLength : integer;
  i : integer;
begin
  //Tvalue.Make<T> only in 10.4 and does this anyway
  Tvalue.Make(@value, System.TypeInfo(T), thevalue);
  if thevalue.IsArray then
  begin
    arrayLength := thevalue.GetArrayLength;
    if arrayLength = 0 then
    begin
      WriteLine;//writeline always writes newline
      exit;
    end;
    for i := 0 to arrayLength -1 do
    begin
      arrayElement := thevalue.GetArrayElement(i);
      Write(arrayElement.ToString + sLineBreak);
    end;
    exit;
  end;

  if thevalue.IsObject and (thevalue.TypeInfo.Kind <> tkInterface) then
  begin
    WriteLine(thevalue.AsObject);
    exit;
  end;

  if thevalue.TypeInfo.Kind = tkRecord then
  begin
    WriteLine('WriteLine<T> - unsupported type : record');
    exit;
  end;
  Write(thevalue.ToString + sLineBreak);
end;

procedure TConsoleImplementation.WriteLine(c: Char);
begin
  WriteString(c + sLineBreak);
end;

procedure TConsoleImplementation.WriteLine(value: boolean);
begin
  WriteString(BoolToStr(value, true) + sLineBreak);
end;

procedure TConsoleImplementation.Write(c: Char);
begin
  WriteString(string(c));
end;

procedure TConsoleImplementation.WriteLine;
begin
  WriteString(sLineBreak);
end;


{ TConsoleImplFactory }

class function TConsoleImplFactory.CreateConsole: TConsoleImplementation;
begin
  {$IFDEF MSWINDOWS}
  result := TWindowsConsole.Create;
  {$ELSEIF MACOS }
  result := TPosixConsole.Create;
  {$ELSEIF LINUX }
  result := TPosixConsole.Create;
  {$ELSE}
    Invalid platform
  {$IFEND}
end;



end.
