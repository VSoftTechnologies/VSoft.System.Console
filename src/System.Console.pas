unit System.Console;

interface

{$I 'System.Console.inc'}

uses
  System.Types,
  System.Classes,
  System.SysUtils,
  System.Console.InternalTypes,
  System.Console.Types;


//these are just to make this file smaller/easier to read whilst allowing consumers to just reference this unit
//in their uses clause.
type
  TConsoleKey       = System.Console.Types.TConsoleKey;
  TConsoleColor     = System.Console.Types.TConsoleColor;
  TConsoleModifier  = System.Console.Types.TConsoleModifier;
  TConsoleModifiers = System.Console.Types.TConsoleModifiers;
  TConsoleSpecialKey = System.Console.Types.TConsoleSpecialKey;
  TConsoleCancelEventArgs = System.Console.Types.TConsoleCancelEventArgs;
  TConsoleCancelEventHandler  = System.Console.Types.TConsoleCancelEventHandler;

  EUnsupportedException = System.Console.Types.EUnsupportedException;

type
  Console = class
  private
  class var
    FConsole : TConsoleImplementation;
    FRaiseUnsupported : boolean;
    FSyncObject : TObject;

    FStdInput   : TTextReader;
    FStdOutput  : TTextWriter;
    FStdError   : TTextWriter;

    FIsOutTextWriterRedirected : boolean;
    FIsErrTextWriterRedirected : boolean;

    FInputEncoding : TEncoding;
    FOutputEncoding : TEncoding;
  protected
    class constructor Create;
    class destructor Destroy;
    class function GetBackgroundColor: TConsoleColor; static;
    class procedure SetBackgroundColor(const value: TConsoleColor); static;
    class function GetForegroundColor: TConsoleColor; static;
    class procedure SetForegroundColor(const value: TConsoleColor); static;

    class function GetIsErrorRedirected : boolean;static;
    class function GetIsInputRedirected : boolean;static;
    class function GetIsOutputRedirected: boolean;static;

    class function GetOutputEncoding : TEncoding;static;
    class procedure SetOutputEncoding(const value : TEncoding);static;

    class function GetInputEncoding : TEncoding;static;
    class procedure SetInputEncoding(const value : TEncoding);static;

    class function GetCursorLeft : integer; static;
    class procedure SetCursorLeft(value : integer); static;

    class function GetCursorTop : integer; static;
    class procedure SetCursorTop(value : integer); static;

    class function GetCursorSize : integer;static;
    class procedure SetCursorSize(value : integer); static;

    class function GetCursorVisible : boolean;static;
    class procedure SetCursorVisible(value : boolean); static;

    class function GetTitle : string;static;
    class procedure SetTitle(const value : string);static;

    class function GetBufferWidth : integer;static;
    class procedure SetBufferWidth(value : integer);static;

    class function GetBufferHeight : integer;static;
    class procedure SetBufferHeight(value : integer);static;

    class function GetWindowWidth : integer; static;
    class procedure SetWindowWidth(value : integer); static;

    class function GetWindowHeight : integer; static;
    class procedure SetWindowHeight(value : integer); static;

    class function GetWindowLeft : integer; static;
    class procedure SetWindowLeft(value : integer); static;

    class function GetWindowTop : integer; static;
    class procedure SetWindowTop(value : integer); static;


    class function GetLargestWindowHeight : integer;static;
    class function GetLargestWindowWidth : integer;static;

    class function GetStdInput : TTextReader;static;
    class function GetStdOutput : TTextWriter;static;
    class function GetStdError : TTextWriter;static;

    class function GetCapsLock: boolean; static;
    class function GetNumLock: boolean; static;
    class function GetKeyAvailable : boolean;static;
    class function GetTreatControlCAsInput: boolean;static;
    class procedure SetTreatControlCAsInput(value : boolean);static;

    class function GetCancelKeyPress : TConsoleCancelEventHandler;static;
    class procedure SetCancelKeyPress(value : TConsoleCancelEventHandler);static;
  public
    class procedure Beep(frequency : Cardinal; duration: Cardinal); overload; static;
    class procedure Beep; overload; static;

    class procedure Clear;

    class procedure MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop: integer); overload;static;
    class procedure MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop: integer; sourceChar: Char; sourceForeColor, sourceBackColor: TConsoleColor); overload;static;

    class procedure SetBufferSize(width : integer; height : integer);static;

    class function OpenStandardInput  : TStream;static;
    class function OpenStandardOutput : TStream;static;
    class function OpenStandardError  : TStream;static;


    class procedure ResetColor;static;

    class function Read : integer; static;
    class function ReadKey(intercept: boolean) : TConsoleKeyInfo; overload; static;
    class function ReadKey : TConsoleKeyInfo; overload; static;
    class function ReadLine : string; static;


    //single operation, slightly faster than setting individually.
    class procedure SetColors(foreground : TConsoleColor; background : TConsoleColor);static;

    class procedure Write(value : boolean);overload;static;
    class procedure Write(value : boolean; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure Write(value : Char);overload;static;
    class procedure Write(value : Char; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure Write(value : TArray<Char>);overload;static;
    class procedure Write(value : TArray<Char>; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure Write<T>(const value : T);overload;static;
    class procedure Write<T>(const value : T; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure Write(const value : string);overload;
    class procedure Write(const value : string; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure Write(const value : TObject);overload;
    class procedure Write(const value : TObject; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure WriteLine;overload;static;

    class procedure WriteLine(value : boolean);overload;
    class procedure WriteLine(value : boolean; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure WriteLine(value : Char);overload;static;
    class procedure WriteLine(value : Char; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure WriteLine(const value : TObject);overload;static;
    class procedure WriteLine(const value : TObject; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure WriteLine<T>(const value : T);overload;static;
    class procedure WriteLine<T>(const value : T; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class procedure WriteLine(const value : string);overload;static;
    class procedure WriteLine(const value : string; foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);overload;static;

    class function GetCursorPosition : TPoint;static;
    class procedure SetCursorPosition(x : integer; y : integer);static;

    class procedure SetWindowSize(width : integer; height : integer);static;
    class procedure SetWindowPosition(left, top: integer);static;
    class function GetWindowPosition : TPoint;static;

    //properties
    class property BackgroundColor : TConsoleColor read GetBackgroundColor write SetBackgroundColor;
    class property ForegroundColor : TConsoleColor read GetForegroundColor write SetForegroundColor;

    class property IsErrorRedirected  : boolean read GetIsErrorRedirected;
    class property IsInputRedirected  : boolean read GetIsInputRedirected;
    class property IsOutputRedirected : boolean read GetIsErrorRedirected;

    class property OutputEncoding : TEncoding read GetOutputEncoding write SetOutputEncoding;
    class property InputEncoding  : TEncoding read GetInputEncoding write SetInputEncoding;


    class property CursorLeft   : integer read GetCursorLeft write SetCursorLeft;
    class property CursorTop    : integer read GetCursorTop write SetCursorTop;
    class property CursorSize   : integer read GetCursorSize write SetCursorSize;
    class property CursorVisible: boolean read GetCursorVisible write SetCursorVisible;


    class property StdInput   : TTextReader read GetStdInput;
    class property StdOutput  : TTextWriter read GetStdOutput;
    class property StdError   : TTextWriter read GetStdError;

    class property Title : string read GetTitle write SetTitle;

    //throw exception if unsupported method called (not all platforms will support everything) - default is true
    class property RaiseUnsupported : boolean read FRaiseUnsupported write FRaiseUnsupported;

    class property BufferHeight : integer read GetBufferHeight write SetBufferHeight;
    class property BufferWidth  : integer read GetBufferWidth write SetBufferWidth;

    class property WindowHeight : integer read GetWindowHeight write SetWindowHeight;
    class property WindowWidth  : integer read GetWindowWidth write SetWindowWidth;

    class property WindowLeft   : integer read GetWindowLeft write SetWindowLeft;
    class property WindowTop    : integer read GetWindowTop write SetWindowTop;

    class property LargestWindowHeight : integer read GetLargestWindowHeight;
    class property LargestWindowWidth : integer read GetLargestWindowWidth;


    class property CapsLock : boolean read GetCapsLock;
    class property NumLock  : boolean read GetNumLock;
    class property KeyAvailable : boolean read GetKeyAvailable;
    class property TreatControlCAsInput : boolean read GetTreatControlCAsInput write SetTreatControlCAsInput;

    class property CancelKeyPress : TConsoleCancelEventHandler read GetCancelKeyPress write SetCancelKeyPress;
  end;

implementation

uses
  System.SyncObjs,
  System.Console.StreamWriter;

{ TConsole }

class procedure Console.Beep;
begin
  FConsole.Beep;
end;

class procedure Console.Beep(frequency, duration: Cardinal);
begin
  FConsole.Beep(frequency, duration);
end;

class procedure Console.Clear;
begin
  FConsole.Clear;
end;

class constructor Console.Create;
begin
  FSyncObject := TObject.Create;
  FConsole := TConsoleImplFactory.CreateConsole;
  FRaiseUnsupported := true;
end;



class destructor Console.Destroy;
begin
  FSyncObject.Free;
end;

class procedure Console.Write(value: boolean);
begin
  StdOutput.Write(value);
end;

class procedure Console.Write(value : Char);
begin
  StdOutput.Write(value);
end;

class procedure Console.Write(value : TArray<Char>);
begin
  StdOutput.Write(value);
end;

class function Console.GetBackgroundColor: TConsoleColor;
begin
  result := FConsole.GetBackgroundColor;
end;



class function Console.GetBufferHeight: integer;
begin
  result := FConsole.GetBufferHeight;
end;

class function Console.GetBufferWidth: integer;
begin
  result := FConsole.GetBufferWidth;
end;

class function Console.GetCancelKeyPress: TConsoleCancelEventHandler;
begin
  result := FConsole.GetCancelKeyPress();
end;

class function Console.GetCapsLock: boolean;
begin
  result := FConsole.GetCapsLock;
end;

class function Console.GetCursorLeft: integer;
begin
  result := FConsole.GetCursorLeft;
end;

class function Console.GetCursorPosition: TPoint;
begin
  result := FConsole.GetcursorPosition;
end;

class function Console.GetCursorSize: integer;
begin
  result := FConsole.GetCursorSize;
end;

class function Console.GetCursorTop: integer;
begin
  result := FConsole.GetCursorTop;
end;

class function Console.GetCursorVisible: boolean;
begin
  result := FConsole.GetCursorVisible;
end;

class function Console.GetForegroundColor: TConsoleColor;
begin
  result := FConsole.GetForegroundColor;
end;

class function Console.GetInputEncoding: TEncoding;
begin
  if FInputEncoding = nil then
  begin
    MonitorEnter(FSyncObject);
    try
      FInputEncoding := FConsole.GetConsoleInputEncoding;
    finally
      MonitorExit(FSyncObject);
    end;
  end;
  result := FInputEncoding;
end;

class function Console.GetIsErrorRedirected: boolean;
begin
  result := FConsole.GetIsErrorRedirected;
end;

class function Console.GetIsInputRedirected: boolean;
begin
  result := FConsole.GetIsInputRedirected;
end;

class function Console.GetIsOutputRedirected: boolean;
begin
  result := FConsole.GetIsOutputRedirected;
end;


class function Console.GetKeyAvailable: boolean;
begin
  result := FConsole.GetKeyAvailable;
end;

class function Console.GetLargestWindowHeight: integer;
begin
  result := FConsole.GetLargestWindowHeight;
end;

class function Console.GetLargestWindowWidth: integer;
begin
  result := FConsole.GetLargestWindowWidth;
end;

class function Console.GetNumLock: boolean;
begin
  result := FConsole.GetNumLock;
end;

class function Console.GetOutputEncoding: TEncoding;
begin
  if FOutputEncoding = nil then
  begin
    MonitorEnter(FSyncObject);
    try
      FOutputEncoding := FConsole.GetConsoleOutputEncoding;
    finally
      MonitorExit(FSyncObject);
    end;
  end;
  result := FOutputEncoding;
end;

class function Console.GetStdError: TTextWriter;
var
  stream : TStream;
  newWriter : TTextWriter;
begin
  if FStdError = nil then
  begin
    MonitorEnter(FSyncObject);
    try
      stream := OpenStandardError;
      newWriter := TConsoleStreamWriter.Create(stream,OutputEncoding);
      TStreamWriter(newWriter).OwnStream;
      if TInterlocked.CompareExchange(Pointer(FStdError), Pointer(newWriter), nil) <> nil then
        //Another thread beat us. Destroy our newly created object and use theirs.
        newWriter.Free;

    finally
      MonitorExit(FSyncObject);
    end;
  end;
  result := FStdError;
end;

class function Console.GetStdInput: TTextReader;
var
  newReader : TTextReader;
begin
  if FStdInput = nil then
  begin
    newReader := FConsole.GetOrCreateReader;
    if TInterlocked.CompareExchange(Pointer(FStdInput), Pointer(newReader), nil) <> nil then
      //Another threadbeat us. Destroy our newly created object and use theirs.
      newReader.Free;
  end;
  result := FStdInput;
end;

class function Console.GetStdOutput: TTextWriter;
var
  stream : TStream;
  newWriter : TTextWriter;
begin
  if FStdOutput = nil then
  begin
    MonitorEnter(FSyncObject);
    try
      stream := OpenStandardOutput;
      newWriter := TConsoleStreamWriter.Create(stream,OutputEncoding);
      TStreamWriter(newWriter).OwnStream;
      if TInterlocked.CompareExchange(Pointer(FStdOutput), Pointer(newWriter), nil) <> nil then
        //Another thread beat us. Destroy our newly created object and use theirs.
        newWriter.Free;

    finally
      MonitorExit(FSyncObject);
    end;
  end;
  result := FStdOutput;
end;

class function Console.GetTitle: string;
begin
  result := FConsole.GetTitle;
end;

class function Console.GetTreatControlCAsInput: boolean;
begin
  result := FConsole.GetTreatControlCAsInput;
end;

class function Console.GetWindowHeight: integer;
begin
  result := FConsole.GetWindowSize.Height;
end;

class function Console.GetWindowLeft: integer;
begin
  result := FConsole.GetWindowPosition.X;
end;

class function Console.GetWindowPosition: TPoint;
begin
  result := FConsole.GetWindowPosition;
end;

class function Console.GetWindowTop: integer;
begin
  result := FConsole.GetWindowPosition.Y;
end;

class function Console.GetWindowWidth: integer;
begin
  result := FConsole.GetWindowSize.Width;
end;

class procedure Console.MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop: integer; sourceChar: Char; sourceForeColor, sourceBackColor: TConsoleColor);
begin
{$IFDEF MSWINDOWS}
  FConsole.MoveBufferArea(sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop, sourceChar, sourceForeColor, sourceBackColor);
{$ENDIF}
end;

class procedure Console.MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop: integer);
begin
  FConsole.MoveBufferArea(sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop);
end;

class function Console.OpenStandardError: TStream;
begin
  result := FConsole.OpenStandardError;
end;

class function Console.OpenStandardInput: TStream;
begin
  result := FConsole.OpenStandardInput;
end;

class function Console.OpenStandardOutput: TStream;
begin
  result := FConsole.OpenStandardOutput;
end;

class function Console.Read: integer;
begin
  result := StdInput.Read;
end;

class function Console.ReadKey(intercept: boolean): TConsoleKeyInfo;
begin
  result := FConsole.ReadKey(intercept);
end;

class function Console.ReadKey: TConsoleKeyInfo;
begin
  result := FConsole.ReadKey(false);
end;

class function Console.ReadLine: string;
begin
  result := StdInput.ReadLine;
end;

class procedure Console.ResetColor;
begin
  FConsole.ResetColors;
end;

class procedure Console.SetBackgroundColor(const value: TConsoleColor);
begin
  FConsole.SetBackgroundColor(value);
end;

class procedure Console.SetBufferHeight(value: integer);
begin
  FConsole.SetBufferHeight(value);
end;

class procedure Console.SetBufferSize(width, height: integer);
begin
  FConsole.SetBufferSize(width, height);
end;

class procedure Console.SetBufferWidth(value: integer);
begin
  FConsole.SetBufferWidth(value);
end;

class procedure Console.SetCursorPosition(x, y: integer);
begin
  FConsole.SetCursorPosition(x, y);
end;

class procedure Console.SetCursorSize(value: integer);
begin
  FConsole.SetCursorSize(value);
end;

class procedure Console.SetCancelKeyPress(value: TConsoleCancelEventHandler);
begin
  FConsole.SetCancelKeyPress(value);
end;

class procedure Console.SetColors(foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
end;

class procedure Console.SetCursorLeft(value : integer);
begin
  FConsole.SetCursorLeft(value)
end;

class procedure Console.SetCursorTop(value : integer);
begin
  FConsole.SetCursorTop(value);
end;

class procedure Console.SetCursorVisible(value: boolean);
begin
  FConsole.SetCursorVisible(value);
end;

class procedure Console.SetForegroundColor(const value: TConsoleColor);
begin
  FConsole.SetForegroundColor(value);
end;

class procedure Console.SetInputEncoding(const value: TEncoding);
begin
  MonitorEnter(FSyncObject);
  try
    FConsole.SetConsoleInputEncoding(value);
    FInputEncoding := FConsole.GetConsoleInputEncoding; //handles cloning
  finally
    MonitorExit(FSyncObject);
  end;
end;

class procedure Console.SetOutputEncoding(const value: TEncoding);
begin
  MonitorEnter(FSyncObject);
  try
    FConsole.SetConsoleOutputEncoding(value);

    if (FStdOutput <> nil) and (not FIsOutTextWriterRedirected) then
    begin
      FStdOutput.Flush;
      FreeAndNil(FStdOutput);
    end;

    if (FStdError <> nil) and (not FIsErrTextWriterRedirected) then
    begin
      FStdError.Flush;
      FreeAndNil(FStdError);
    end;
    FOutputEncoding := FConsole.GetConsoleOutputEncoding; //handles cloning
  finally
    MonitorExit(FSyncObject);
  end;
end;

class procedure Console.SetTitle(const value : string);
begin
  FConsole.SetTitle(value)
end;

class procedure Console.SetTreatControlCAsInput(value: boolean);
begin
  FConsole.SetTreatControlCAsInput(value);
end;

class procedure Console.SetWindowHeight(value: integer);
begin
  FConsole.SetWindowSize(GetWindowWidth, value);
end;

class procedure Console.SetWindowLeft(value: integer);
begin
  FConsole.SetWindowPosition(value, GetWindowTop);
end;

class procedure Console.SetWindowPosition(left, top: integer);
begin
  FConsole.SetWindowPosition(left, top);
end;

class procedure Console.SetWindowSize(width, height: integer);
begin
  FConsole.SetWindowSize(width, height);
end;

class procedure Console.SetWindowTop(value: integer);
begin
  FConsole.SetWindowPosition(GetWindowLeft, value);
end;

class procedure Console.SetWindowWidth(value: integer);
begin
  FConsole.SetWindowSize(value, GetWindowHeight);
end;

class procedure Console.Write(const value : TObject);
begin
  StdOutput.Write(value);
end;

class procedure Console.Write(const value : string; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.Write(value);
end;

class procedure Console.Write(value : TArray<Char>; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.Write(value);
end;

class procedure Console.Write(value : Char; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.Write(value);
end;

class procedure Console.Write(value: boolean; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.Write(value);
end;

class procedure Console.Write(const value : string);
begin
  StdOutput.Write(value);
end;

class procedure Console.WriteLine(const value: string);
begin
  StdOutput.WriteLine(value);
end;

class procedure Console.WriteLine(const value: string; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.WriteLine(value);
end;

class procedure Console.WriteLine<T>(const value: T; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  FConsole.WriteLine(value); //TODO move code here
end;

class procedure Console.WriteLine(const value : TObject; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.WriteLine(value);
end;

class procedure Console.WriteLine(value: Char; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.WriteLine(value);
end;

class procedure Console.WriteLine(value: boolean; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.WriteLine(value);
end;

class procedure Console.WriteLine<T>(const value: T);
begin
  FConsole.WriteLine<T>(value); //TODO : move code here
end;

class procedure Console.WriteLine;
begin
  StdOutput.WriteLine;
end;

class procedure Console.Write<T>(const value : T);
begin
  FConsole.Write<T>(value); //TODO : move code here
end;

class procedure Console.WriteLine(value : boolean);
begin
  StdOutput.WriteLine(value);
end;

class procedure Console.WriteLine(value : Char);
begin
  StdOutput.WriteLine(value );
end;

class procedure Console.WriteLine(const value : TObject);
begin
  StdOutput.WriteLine(value);
end;

class procedure Console.Write(const value : TObject; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  StdOutput.WriteLine(value);
end;

class procedure Console.Write<T>(const value: T; foreground, background: TConsoleColor);
begin
  FConsole.SetColors(foreground, background);
  FConsole.Write<T>(value); //todo move code here
end;

end.
