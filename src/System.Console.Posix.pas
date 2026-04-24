unit System.Console.Posix;

interface

{$I 'System.Console.inc'}

uses
  System.SysUtils,
  System.Types,
  System.Classes,
  System.Console.Types,
  System.Console.InternalTypes,
  System.Console.ConsoleStream
  {$IFDEF POSIX}
  ,Posix.Base
  ,Posix.Errno
  ,Posix.Unistd
  ,Posix.Termios
  ,Posix.SysIoctl
  ,Posix.SysSelect
  ,Posix.SysTime
  ,Posix.Signal
  ,Posix.StdLib
  ,Posix.Fcntl
  {$ENDIF}
  ;

type
  {$IFDEF POSIX}
  TPosixSignalDispatcher = class(TThread)
  private
    FReadEnd  : Int32;
    FWriteEnd : Int32;
    FHandler  : TConsoleCancelEventHandler;
    FOwner    : TObject;
  protected
    procedure Execute; override;
  public
    constructor Create(const owner : TObject; readEnd : Int32; writeEnd : Int32);
    procedure Stop;
    procedure SetHandler(const value : TConsoleCancelEventHandler);
    function GetHandler : TConsoleCancelEventHandler;
    property WriteEnd : Int32 read FWriteEnd;
  end;
  {$ENDIF}

  TPosixConsole = class(TConsoleImplementation)
  private
  {$IFDEF POSIX}
    FStdIn  : Int32;
    FStdOut : Int32;
    FStdErr : Int32;

    FOutputEncoding : TEncoding;
    FInputEncoding  : TEncoding;

    FOriginalTermios : termios;
    FTermiosSaved    : Boolean;
    FIsRawMode       : Boolean;
    FTreatControlCAsInput : Boolean;

    FCurrentFG : TConsoleColor;
    FCurrentBG : TConsoleColor;
    FInitialFG : TConsoleColor;
    FInitialBG : TConsoleColor;
    FSavedFG   : TConsoleColor;
    FSavedBG   : TConsoleColor;

    FTrackedCursorX : Integer;
    FTrackedCursorY : Integer;
    FCursorVisible  : Boolean;
    FCursorSize     : Integer;

    FCachedTitle : string;

    FReadBuffer    : array of Byte;
    FReadBufferLen : Integer;

    FCancelKeyPress   : TConsoleCancelEventHandler;
    FSignalDispatcher : TPosixSignalDispatcher;

    FReadKeySyncObject : TObject;

    procedure WriteRaw(const bytes : TBytes); overload;
    procedure WriteRaw(const s : RawByteString); overload;
    function ColorToFgCode(c : TConsoleColor) : Integer;
    function ColorToBgCode(c : TConsoleColor) : Integer;
    procedure EmitColor(foreground : TConsoleColor; background : TConsoleColor);
    function GetWinSize(out cols : Integer; out rows : Integer) : Boolean;
    procedure EnsureRawMode;
    procedure ApplyTermiosMode;
    procedure RestoreTermios;
    function WaitForInput(timeoutMs : Integer) : Boolean;
    function ReadByteBlocking(out b : Byte) : Boolean;
    function ReadByteTimed(timeoutMs : Integer; out b : Byte) : Boolean;
    procedure PushbackBytes(const bytes : array of Byte);
    function MapControlChar(b : Byte) : TConsoleKeyInfo;
    function DecodeUtf8Char(leadByte : Byte; out ch : Char) : Boolean;
    function ParseCsiSequence(out info : TConsoleKeyInfo) : Boolean;
    function ParseSs3Sequence(out info : TConsoleKeyInfo) : Boolean;
    procedure UpdateCursorForString(const value : string);
    procedure InstallExitSignalHandlers;
    procedure TearDownCancelHandler;
  {$ENDIF}
  protected
    function PlatformName : string; override;
    procedure WriteString(const value : string); override;
    procedure SetTempColors(foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet); override;
    procedure RestoreColors; override;
  public
    constructor Create;
    destructor Destroy; override;

    function OpenStandardInput  : TStream; override;
    function OpenStandardOutput : TStream; override;
    function OpenStandardError  : TStream; override;

    function GetOrCreateReader : TTextReader; override;

    function GetBackgroundColor : TConsoleColor; override;
    procedure SetBackgroundColor(value : TConsoleColor); override;
    function GetForegroundColor : TConsoleColor; override;
    procedure SetForegroundColor(value : TConsoleColor); override;

    procedure SetColors(foreground : TConsoleColor; background : TConsoleColor); override;
    procedure ResetColors; override;

    function GetBufferWidth : integer; override;
    procedure SetBufferWidth(value : integer); override;
    function GetBufferHeight : integer; override;
    procedure SetBufferHeight(value : integer); override;
    procedure SetBufferSize(width : integer; height : integer); override;

    function GetCursorPosition : TPoint; override;
    procedure SetCursorPosition(x : integer; y : integer); override;
    function GetCursorLeft : integer; override;
    procedure SetCursorLeft(value : integer); override;
    function GetCursorTop : integer; override;
    procedure SetCursorTop(value : integer); override;
    function GetCursorSize : integer; override;
    procedure SetCursorSize(value : integer); override;
    function GetCursorVisible : boolean; override;
    procedure SetCursorVisible(value : boolean); override;

    function GetTitle : string; override;
    procedure SetTitle(const value : string); override;

    function GetIsErrorRedirected  : boolean; override;
    function GetIsInputRedirected  : boolean; override;
    function GetIsOutputRedirected : boolean; override;

    function GetConsoleOutputEncoding : TEncoding; override;
    procedure SetConsoleOutputEncoding(const value : TEncoding); override;
    function GetConsoleInputEncoding : TEncoding; override;
    procedure SetConsoleInputEncoding(const value : TEncoding); override;

    function GetWindowSize : TSize; override;
    procedure SetWindowSize(const width : integer; height : integer); override;
    function GetWindowPosition : TPoint; override;
    procedure SetWindowPosition(Left : integer; Top : integer); override;
    function GetLargestWindowHeight : integer; override;
    function GetLargestWindowWidth  : integer; override;

    function GetCancelKeyPress : TConsoleCancelEventHandler; override;
    procedure SetCancelKeyPress(value : TConsoleCancelEventHandler); override;

    procedure Beep(frequency : Cardinal; duration : Cardinal); overload; override;
    procedure Beep; overload; override;

    procedure Clear; override;

    function GetKeyAvailable : boolean; override;
    function ReadKey(intercept : boolean) : TConsoleKeyInfo; override;

    function GetCapsLock : boolean; override;
    function GetNumLock  : boolean; override;
    function GetTreatControlCAsInput : boolean; override;
    procedure SetTreatControlCAsInput(value : boolean); override;
  end;

  {$IFDEF POSIX}
  TPosixConsoleStream = class(TConsoleStream)
  public
    constructor Create(fd : Int32; access : TFileAccess);
    function Read(var Buffer; Count : Longint) : Longint; override;
    function Write(const Buffer; Count : Longint) : Longint; override;
  end;
  {$ENDIF}

implementation

uses
  System.Console.SyncTextReader;

{$IFDEF POSIX}

const
  ESC = #27;
  CSI = #27'[';
  BEL = #7;

  SIGINT_VAL  = 2;
  SIGTERM_VAL = 15;
  SIGHUP_VAL  = 1;

  EXIT_CODE_SIGINT = 130;

  READ_BUFFER_INITIAL = 64;

var
  _instance : TPosixConsole;

// Async-signal-safe SIGINT handler: write a single byte to the self-pipe.
// Do not call anything other than write() / _exit() here.
procedure _PosixSigIntHandler(sig : Integer); cdecl;
var
  c : Byte;
  disp : TPosixSignalDispatcher;
begin
  c := Ord('C');
  if _instance <> nil then
  begin
    disp := _instance.FSignalDispatcher;
    if disp <> nil then
      __write(disp.WriteEnd, @c, 1);
  end;
end;

// SIGTERM / SIGHUP: restore termios and exit. tcsetattr is async-signal-safe.
procedure _PosixTermHandler(sig : Integer); cdecl;
begin
  if _instance <> nil then
  begin
    if _instance.FTermiosSaved then
      tcsetattr(_instance.FStdIn, TCSANOW, _instance.FOriginalTermios);
  end;
  _exit(128 + sig);
end;

{ TPosixSignalDispatcher }

constructor TPosixSignalDispatcher.Create(const owner : TObject; readEnd : Int32; writeEnd : Int32);
begin
  FOwner    := owner;
  FReadEnd  := readEnd;
  FWriteEnd := writeEnd;
  FHandler  := nil;
  FreeOnTerminate := false;
  inherited Create(false);
end;

procedure TPosixSignalDispatcher.SetHandler(const value : TConsoleCancelEventHandler);
begin
  MonitorEnter(Self);
  try
    FHandler := value;
  finally
    MonitorExit(Self);
  end;
end;

function TPosixSignalDispatcher.GetHandler : TConsoleCancelEventHandler;
begin
  MonitorEnter(Self);
  try
    result := FHandler;
  finally
    MonitorExit(Self);
  end;
end;

procedure TPosixSignalDispatcher.Execute;
var
  b       : Byte;
  n       : ssize_t;
  handler : TConsoleCancelEventHandler;
  args    : TConsoleCancelEventArgs;
begin
  while not Terminated do
  begin
    n := __read(FReadEnd, @b, 1);
    if n <= 0 then
    begin
      if Terminated then
        exit;
      continue;
    end;
    if b = Ord('Q') then
      exit;
    if b <> Ord('C') then
      continue;

    handler := GetHandler;
    if not Assigned(handler) then
      continue;

    args := TConsoleCancelEventArgs.Create(TConsoleSpecialKey.ControlC);
    try
      try
        handler(FOwner, args);
      except
        // Swallow exceptions from user handler so the dispatcher thread survives.
      end;
      if not args.Cancel then
        _exit(EXIT_CODE_SIGINT);
    finally
      args.Free;
    end;
  end;
end;

procedure TPosixSignalDispatcher.Stop;
var
  b : Byte;
begin
  Terminate;
  // Wake the read by sending a 'Q' byte.
  b := Ord('Q');
  __write(FWriteEnd, @b, 1);
  WaitFor;
end;

{ TPosixConsoleStream }

constructor TPosixConsoleStream.Create(fd : Int32; access : TFileAccess);
begin
  inherited Create(THandle(fd), access);
end;

function TPosixConsoleStream.Read(var Buffer; Count : Longint) : Longint;
var
  n     : ssize_t;
  total : Longint;
  p     : PByte;
begin
  if not FCanRead then
    raise EInvalidOperation.Create('Stream does not support reading');
  result := 0;
  if Count <= 0 then
    exit;

  total := 0;
  p := PByte(@Buffer);
  while total < Count do
  begin
    n := __read(Int32(FHandle), p, Count - total);
    if n < 0 then
    begin
      // EINTR => retry; any other error ends the read.
      if GetLastError = EINTR then
        continue;
      exit(total);
    end;
    if n = 0 then
      break; // EOF
    Inc(p, n);
    Inc(total, n);
    // A short read on a TTY typically means the line is done; don't block for more.
    break;
  end;
  result := total;
end;

function TPosixConsoleStream.Write(const Buffer; Count : Longint) : Longint;
var
  n     : ssize_t;
  total : Longint;
  p     : PByte;
begin
  if not FCanWrite then
    raise EInvalidOperation.Create('Stream does not support writing');
  result := 0;
  if Count <= 0 then
    exit;

  total := 0;
  p := PByte(@Buffer);
  while total < Count do
  begin
    n := __write(Int32(FHandle), p, Count - total);
    if n < 0 then
    begin
      if GetLastError = EINTR then
        continue;
      exit(total);
    end;
    if n = 0 then
      break;
    Inc(p, n);
    Inc(total, n);
  end;
  result := total;
end;

{$ENDIF POSIX}

{ TPosixConsole }

constructor TPosixConsole.Create;
begin
  inherited Create;
{$IFDEF POSIX}
  _instance := Self;
  FReadKeySyncObject := TObject.Create;

  FStdIn  := STDIN_FILENO;
  FStdOut := STDOUT_FILENO;
  FStdErr := STDERR_FILENO;

  FInitialFG := TConsoleColor.Gray;
  FInitialBG := TConsoleColor.Black;
  FCurrentFG := FInitialFG;
  FCurrentBG := FInitialBG;
  FSavedFG   := FInitialFG;
  FSavedBG   := FInitialBG;

  FTrackedCursorX := 0;
  FTrackedCursorY := 0;
  FCursorVisible  := true;
  FCursorSize     := 25;
  FIsRawMode      := false;
  FTermiosSaved   := false;
  FTreatControlCAsInput := false;

  SetLength(FReadBuffer, READ_BUFFER_INITIAL);
  FReadBufferLen := 0;

  if isatty(FStdIn) <> 0 then
  begin
    if tcgetattr(FStdIn, FOriginalTermios) = 0 then
      FTermiosSaved := true;
  end;

  InstallExitSignalHandlers;
{$ENDIF}
end;

destructor TPosixConsole.Destroy;
begin
{$IFDEF POSIX}
  TearDownCancelHandler;
  RestoreTermios;
  if FReadKeySyncObject <> nil then
    FreeAndNil(FReadKeySyncObject);
  if (FOutputEncoding <> nil) and (not TEncoding.IsStandardEncoding(FOutputEncoding)) then
    FreeAndNil(FOutputEncoding);
  if (FInputEncoding <> nil) and (not TEncoding.IsStandardEncoding(FInputEncoding)) then
    FreeAndNil(FInputEncoding);
  if _instance = Self then
    _instance := nil;
{$ENDIF}
  inherited;
end;

function TPosixConsole.PlatformName : string;
begin
{$IFDEF MACOS}
  result := 'macOS';
{$ELSEIF defined(LINUX)}
  result := 'Linux';
{$ELSE}
  result := 'POSIX';
{$IFEND}
end;

{$IFDEF POSIX}

procedure TPosixConsole.InstallExitSignalHandlers;
begin
  // Minimal, best-effort: install SIGTERM/SIGHUP so we restore termios on shutdown.
  // Use signal() for portability over sigaction record layout differences.
  Posix.Signal.signal(SIGTERM_VAL, _PosixTermHandler);
  Posix.Signal.signal(SIGHUP_VAL,  _PosixTermHandler);
end;

procedure TPosixConsole.WriteRaw(const bytes : TBytes);
var
  total : Integer;
  n     : ssize_t;
  p     : PByte;
  len   : Integer;
begin
  len := Length(bytes);
  if len = 0 then
    exit;
  total := 0;
  p := @bytes[0];
  while total < len do
  begin
    n := __write(FStdOut, p, len - total);
    if n < 0 then
    begin
      if GetLastError = EINTR then
        continue;
      exit;
    end;
    if n = 0 then
      break;
    Inc(p, n);
    Inc(total, n);
  end;
end;

procedure TPosixConsole.WriteRaw(const s : RawByteString);
var
  bytes : TBytes;
  i     : Integer;
begin
  if Length(s) = 0 then
    exit;
  SetLength(bytes, Length(s));
  for i := 1 to Length(s) do
    bytes[i - 1] := Byte(s[i]);
  WriteRaw(bytes);
end;

function TPosixConsole.ColorToFgCode(c : TConsoleColor) : Integer;
const
  darkFg   : array[0..7] of Integer = (30, 34, 32, 36, 31, 35, 33, 37);
  brightFg : array[0..7] of Integer = (90, 94, 92, 96, 91, 95, 93, 97);
var
  idx : Integer;
begin
  idx := Integer(c);
  if (idx >= 0) and (idx <= 7) then
    result := darkFg[idx]
  else if (idx >= 8) and (idx <= 15) then
    result := brightFg[idx - 8]
  else
    result := 39; // default foreground
end;

function TPosixConsole.ColorToBgCode(c : TConsoleColor) : Integer;
const
  darkBg   : array[0..7] of Integer = (40, 44, 42, 46, 41, 45, 43, 47);
  brightBg : array[0..7] of Integer = (100, 104, 102, 106, 101, 105, 103, 107);
var
  idx : Integer;
begin
  idx := Integer(c);
  if (idx >= 0) and (idx <= 7) then
    result := darkBg[idx]
  else if (idx >= 8) and (idx <= 15) then
    result := brightBg[idx - 8]
  else
    result := 49; // default background
end;

procedure TPosixConsole.EmitColor(foreground : TConsoleColor; background : TConsoleColor);
var
  s : RawByteString;
begin
  if background = TConsoleColor.NotSet then
    s := RawByteString(CSI + IntToStr(ColorToFgCode(foreground)) + 'm')
  else
    s := RawByteString(CSI + IntToStr(ColorToFgCode(foreground)) + ';' + IntToStr(ColorToBgCode(background)) + 'm');
  WriteRaw(s);
end;

function TPosixConsole.GetWinSize(out cols : Integer; out rows : Integer) : Boolean;
var
  ws : winsize;
begin
  cols := 0;
  rows := 0;
  result := false;
  FillChar(ws, SizeOf(ws), 0);
  if ioctl(FStdOut, TIOCGWINSZ, @ws) = 0 then
  begin
    cols := ws.ws_col;
    rows := ws.ws_row;
    result := (cols > 0) and (rows > 0);
  end;
end;

procedure TPosixConsole.ApplyTermiosMode;
var
  raw : termios;
begin
  if not FTermiosSaved then
    exit;
  raw := FOriginalTermios;
  // Disable canonical mode and echo. Keep ISIG unless the app wants raw ^C as #3.
  raw.c_lflag := raw.c_lflag and (not Cardinal(ICANON));
  raw.c_lflag := raw.c_lflag and (not Cardinal(ECHO));
  if FTreatControlCAsInput then
    raw.c_lflag := raw.c_lflag and (not Cardinal(ISIG))
  else
    raw.c_lflag := raw.c_lflag or Cardinal(ISIG);
  raw.c_cc[VMIN]  := 1;
  raw.c_cc[VTIME] := 0;
  tcsetattr(FStdIn, TCSANOW, raw);
  FIsRawMode := true;
end;

procedure TPosixConsole.EnsureRawMode;
begin
  if FIsRawMode then
    exit;
  ApplyTermiosMode;
end;

procedure TPosixConsole.RestoreTermios;
begin
  if FTermiosSaved then
  begin
    tcsetattr(FStdIn, TCSANOW, FOriginalTermios);
    FIsRawMode := false;
  end;
end;

function TPosixConsole.WaitForInput(timeoutMs : Integer) : Boolean;
var
  fds  : fd_set;
  tv   : timeval;
  n    : Integer;
begin
  if FReadBufferLen > 0 then
    exit(true);
  FD_ZERO(fds);
  _FD_SET(FStdIn, fds);
  tv.tv_sec  := timeoutMs div 1000;
  tv.tv_usec := (timeoutMs mod 1000) * 1000;
  n := select(FStdIn + 1, @fds, nil, nil, @tv);
  result := n > 0;
end;

function TPosixConsole.ReadByteBlocking(out b : Byte) : Boolean;
var
  n : ssize_t;
begin
  if FReadBufferLen > 0 then
  begin
    b := FReadBuffer[0];
    if FReadBufferLen > 1 then
      Move(FReadBuffer[1], FReadBuffer[0], FReadBufferLen - 1);
    Dec(FReadBufferLen);
    exit(true);
  end;

  while true do
  begin
    n := __read(FStdIn, @b, 1);
    if n = 1 then
      exit(true);
    if n < 0 then
    begin
      if GetLastError = EINTR then
        continue;
      exit(false);
    end;
    exit(false); // EOF
  end;
end;

function TPosixConsole.ReadByteTimed(timeoutMs : Integer; out b : Byte) : Boolean;
begin
  if not WaitForInput(timeoutMs) then
    exit(false);
  result := ReadByteBlocking(b);
end;

procedure TPosixConsole.PushbackBytes(const bytes : array of Byte);
var
  i      : Integer;
  needed : Integer;
begin
  if Length(bytes) = 0 then
    exit;
  needed := FReadBufferLen + Length(bytes);
  if needed > Length(FReadBuffer) then
    SetLength(FReadBuffer, needed);
  for i := 0 to High(bytes) do
    FReadBuffer[FReadBufferLen + i] := bytes[i];
  Inc(FReadBufferLen, Length(bytes));
end;

function TPosixConsole.MapControlChar(b : Byte) : TConsoleKeyInfo;
var
  key  : TConsoleKey;
  ch   : Char;
begin
  key := TConsoleKey.None;
  ch  := Char(b);
  case b of
    8, 127 :
      begin
        key := TConsoleKey.Backspace;
        ch  := #8;
      end;
    9 :
      begin
        key := TConsoleKey.Tab;
        ch  := #9;
      end;
    10, 13 :
      begin
        key := TConsoleKey.Enter;
        ch  := #13;
      end;
    27 :
      begin
        key := TConsoleKey.Escape;
        ch  := #27;
      end;
    32 :
      begin
        key := TConsoleKey.Spacebar;
        ch  := ' ';
      end;
    1..7, 11..12, 14..26 :
      begin
        // Ctrl+A..Z (minus the ones mapped above).
        key := TConsoleKey(b + $40); // e.g. #3 -> $43 = 'C'
        result := TConsoleKeyInfo.Create(Char(b), key, false, false, true);
        exit;
      end;
  else
    if (b >= Ord('0')) and (b <= Ord('9')) then
      key := TConsoleKey(b)
    else if (b >= Ord('A')) and (b <= Ord('Z')) then
      key := TConsoleKey(b)
    else if (b >= Ord('a')) and (b <= Ord('z')) then
      key := TConsoleKey(b - 32);
  end;
  result := TConsoleKeyInfo.Create(ch, key, false, false, false);
end;

function TPosixConsole.DecodeUtf8Char(leadByte : Byte; out ch : Char) : Boolean;
var
  count : Integer;
  bytes : TBytes;
  b     : Byte;
  i     : Integer;
  s     : string;
begin
  result := false;
  ch := #0;
  if (leadByte and $80) = 0 then
  begin
    ch := Char(leadByte);
    exit(true);
  end;
  if (leadByte and $E0) = $C0 then
    count := 1
  else if (leadByte and $F0) = $E0 then
    count := 2
  else if (leadByte and $F8) = $F0 then
    count := 3
  else
    exit(false);

  SetLength(bytes, count + 1);
  bytes[0] := leadByte;
  for i := 1 to count do
  begin
    if not ReadByteTimed(50, b) then
      exit(false);
    bytes[i] := b;
  end;
  s := TEncoding.UTF8.GetString(bytes);
  if Length(s) > 0 then
  begin
    ch := s[1];
    result := true;
  end;
end;

function TPosixConsole.ParseSs3Sequence(out info : TConsoleKeyInfo) : Boolean;
var
  b : Byte;
begin
  // ESC O <letter>
  result := false;
  if not ReadByteTimed(50, b) then
    exit;
  case Char(b) of
    'P' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.F1, false, false, false);
    'Q' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.F2, false, false, false);
    'R' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.F3, false, false, false);
    'S' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.F4, false, false, false);
    'H' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.Home, false, false, false);
    'F' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.&End, false, false, false);
    'A' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.UpArrow, false, false, false);
    'B' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.DownArrow, false, false, false);
    'C' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.RightArrow, false, false, false);
    'D' : info := TConsoleKeyInfo.Create(#0, TConsoleKey.LeftArrow, false, false, false);
  else
    exit;
  end;
  result := true;
end;

function TPosixConsole.ParseCsiSequence(out info : TConsoleKeyInfo) : Boolean;
var
  params  : array[0..3] of Integer;
  pCount  : Integer;
  current : Integer;
  hasCur  : Boolean;
  b       : Byte;
  final   : Char;
  modByte : Integer;
  shift   : Boolean;
  alt     : Boolean;
  ctrl    : Boolean;
  key     : TConsoleKey;
  mainVal : Integer;

  procedure FlushParam;
  begin
    if hasCur and (pCount <= High(params)) then
    begin
      params[pCount] := current;
      Inc(pCount);
      current := 0;
      hasCur := false;
    end
    else if not hasCur and (pCount <= High(params)) then
    begin
      params[pCount] := 0;
      Inc(pCount);
    end;
  end;

begin
  result  := false;
  pCount  := 0;
  current := 0;
  hasCur  := false;
  final   := #0;
  FillChar(params, SizeOf(params), 0);

  while true do
  begin
    if not ReadByteTimed(50, b) then
      exit;
    if (b >= Ord('0')) and (b <= Ord('9')) then
    begin
      current := current * 10 + (b - Ord('0'));
      hasCur  := true;
      continue;
    end;
    if b = Ord(';') then
    begin
      FlushParam;
      continue;
    end;
    // Any non-digit, non-semicolon byte ends the sequence.
    if hasCur then
      FlushParam;
    final := Char(b);
    break;
  end;

  shift := false;
  alt   := false;
  ctrl  := false;
  if pCount >= 2 then
  begin
    modByte := params[1];
    if modByte > 1 then
    begin
      Dec(modByte);
      shift := (modByte and 1) <> 0;
      alt   := (modByte and 2) <> 0;
      ctrl  := (modByte and 4) <> 0;
    end;
  end;

  key := TConsoleKey.None;

  if pCount = 0 then
    mainVal := 0
  else
    mainVal := params[0];

  case final of
    'A' : key := TConsoleKey.UpArrow;
    'B' : key := TConsoleKey.DownArrow;
    'C' : key := TConsoleKey.RightArrow;
    'D' : key := TConsoleKey.LeftArrow;
    'H' : key := TConsoleKey.Home;
    'F' : key := TConsoleKey.&End;
    'P' : key := TConsoleKey.F1;
    'Q' : key := TConsoleKey.F2;
    'R' : key := TConsoleKey.F3;
    'S' : key := TConsoleKey.F4;
    'Z' :
      begin
        key := TConsoleKey.Tab;
        shift := true;
      end;
    '~' :
      begin
        case mainVal of
          1, 7  : key := TConsoleKey.Home;
          2     : key := TConsoleKey.Insert;
          3     : key := TConsoleKey.Delete;
          4, 8  : key := TConsoleKey.&End;
          5     : key := TConsoleKey.PageUp;
          6     : key := TConsoleKey.PageDown;
          11    : key := TConsoleKey.F1;
          12    : key := TConsoleKey.F2;
          13    : key := TConsoleKey.F3;
          14    : key := TConsoleKey.F4;
          15    : key := TConsoleKey.F5;
          17    : key := TConsoleKey.F6;
          18    : key := TConsoleKey.F7;
          19    : key := TConsoleKey.F8;
          20    : key := TConsoleKey.F9;
          21    : key := TConsoleKey.F10;
          23    : key := TConsoleKey.F11;
          24    : key := TConsoleKey.F12;
        else
          exit;
        end;
      end;
  else
    exit;
  end;

  info := TConsoleKeyInfo.Create(#0, key, shift, alt, ctrl);
  result := true;
end;

procedure TPosixConsole.UpdateCursorForString(const value : string);
var
  i       : Integer;
  c       : Char;
  cols    : Integer;
  rows    : Integer;
  haveWin : Boolean;
begin
  if value = '' then
    exit;
  haveWin := GetWinSize(cols, rows);
  if not haveWin then
    cols := 80;
  for i := 1 to Length(value) do
  begin
    c := value[i];
    case c of
      #13 : FTrackedCursorX := 0;
      #10 : Inc(FTrackedCursorY);
      #8  : if FTrackedCursorX > 0 then Dec(FTrackedCursorX);
      #9  : FTrackedCursorX := ((FTrackedCursorX div 8) + 1) * 8;
    else
      if c >= #32 then
      begin
        Inc(FTrackedCursorX);
        if (cols > 0) and (FTrackedCursorX >= cols) then
        begin
          FTrackedCursorX := 0;
          Inc(FTrackedCursorY);
        end;
      end;
    end;
  end;
end;

procedure TPosixConsole.TearDownCancelHandler;
begin
  if FSignalDispatcher <> nil then
  begin
    Posix.Signal.signal(SIGINT_VAL, SIG_DFL);
    FSignalDispatcher.Stop;
    if FSignalDispatcher.FReadEnd  <> 0 then __close(FSignalDispatcher.FReadEnd);
    if FSignalDispatcher.FWriteEnd <> 0 then __close(FSignalDispatcher.FWriteEnd);
    FreeAndNil(FSignalDispatcher);
  end;
end;

{$ENDIF POSIX}

procedure TPosixConsole.WriteString(const value : string);
{$IFDEF POSIX}
var
  bytes : TBytes;
{$ENDIF}
begin
{$IFDEF POSIX}
  if value = '' then
    exit;
  if FOutputEncoding = nil then
    GetConsoleOutputEncoding;
  bytes := FOutputEncoding.GetBytes(value);
  WriteRaw(bytes);
  UpdateCursorForString(value);
{$ENDIF}
end;

procedure TPosixConsole.SetTempColors(foreground : TConsoleColor; background : TConsoleColor);
begin
{$IFDEF POSIX}
  FSavedFG := FCurrentFG;
  FSavedBG := FCurrentBG;
  if background <> TConsoleColor.NotSet then
    SetColors(foreground, background)
  else
    SetForegroundColor(foreground);
{$ENDIF}
end;

procedure TPosixConsole.RestoreColors;
begin
{$IFDEF POSIX}
  SetColors(FSavedFG, FSavedBG);
{$ENDIF}
end;

function TPosixConsole.OpenStandardInput : TStream;
begin
{$IFDEF POSIX}
  result := TPosixConsoleStream.Create(FStdIn, TFileAccess.Read);
{$ELSE}
  result := nil;
{$ENDIF}
end;

function TPosixConsole.OpenStandardOutput : TStream;
begin
{$IFDEF POSIX}
  result := TPosixConsoleStream.Create(FStdOut, TFileAccess.Write);
{$ELSE}
  result := nil;
{$ENDIF}
end;

function TPosixConsole.OpenStandardError : TStream;
begin
{$IFDEF POSIX}
  result := TPosixConsoleStream.Create(FStdErr, TFileAccess.Write);
{$ELSE}
  result := nil;
{$ENDIF}
end;

function TPosixConsole.GetOrCreateReader : TTextReader;
{$IFDEF POSIX}
var
  stream : TStream;
  reader : TStreamReader;
{$ENDIF}
begin
{$IFDEF POSIX}
  stream := OpenStandardInput;
  if stream = nil then
    exit(nil);
  reader := TStreamReader.Create(stream, GetConsoleInputEncoding);
  reader.OwnStream;
  result := TSyncTextReader.GetSynchronizedTextReader(reader);
{$ELSE}
  result := nil;
{$ENDIF}
end;

function TPosixConsole.GetBackgroundColor : TConsoleColor;
begin
{$IFDEF POSIX}
  result := FCurrentBG;
{$ELSE}
  result := TConsoleColor.Black;
{$ENDIF}
end;

procedure TPosixConsole.SetBackgroundColor(value : TConsoleColor);
begin
{$IFDEF POSIX}
  FCurrentBG := value;
  WriteRaw(RawByteString(CSI + IntToStr(ColorToBgCode(value)) + 'm'));
{$ENDIF}
end;

function TPosixConsole.GetForegroundColor : TConsoleColor;
begin
{$IFDEF POSIX}
  result := FCurrentFG;
{$ELSE}
  result := TConsoleColor.Gray;
{$ENDIF}
end;

procedure TPosixConsole.SetForegroundColor(value : TConsoleColor);
begin
{$IFDEF POSIX}
  FCurrentFG := value;
  WriteRaw(RawByteString(CSI + IntToStr(ColorToFgCode(value)) + 'm'));
{$ENDIF}
end;

procedure TPosixConsole.SetColors(foreground : TConsoleColor; background : TConsoleColor);
begin
{$IFDEF POSIX}
  FCurrentFG := foreground;
  if background <> TConsoleColor.NotSet then
    FCurrentBG := background;
  EmitColor(foreground, background);
{$ENDIF}
end;

procedure TPosixConsole.ResetColors;
begin
{$IFDEF POSIX}
  WriteRaw(RawByteString(CSI + '0m'));
  FCurrentFG := FInitialFG;
  FCurrentBG := FInitialBG;
{$ENDIF}
end;

function TPosixConsole.GetBufferWidth : integer;
{$IFDEF POSIX}
var
  cols : Integer;
  rows : Integer;
{$ENDIF}
begin
{$IFDEF POSIX}
  if GetWinSize(cols, rows) then
    result := cols
  else
    result := 80;
{$ELSE}
  result := 80;
{$ENDIF}
end;

procedure TPosixConsole.SetBufferWidth(value : integer);
begin
{$IFDEF POSIX}
  SetWindowSize(value, GetBufferHeight);
{$ENDIF}
end;

function TPosixConsole.GetBufferHeight : integer;
{$IFDEF POSIX}
var
  cols : Integer;
  rows : Integer;
{$ENDIF}
begin
{$IFDEF POSIX}
  if GetWinSize(cols, rows) then
    result := rows
  else
    result := 24;
{$ELSE}
  result := 24;
{$ENDIF}
end;

procedure TPosixConsole.SetBufferHeight(value : integer);
begin
{$IFDEF POSIX}
  SetWindowSize(GetBufferWidth, value);
{$ENDIF}
end;

procedure TPosixConsole.SetBufferSize(width : integer; height : integer);
begin
{$IFDEF POSIX}
  SetWindowSize(width, height);
{$ENDIF}
end;

function TPosixConsole.GetCursorPosition : TPoint;
begin
{$IFDEF POSIX}
  result := TPoint.Create(FTrackedCursorX, FTrackedCursorY);
{$ELSE}
  result := TPoint.Create(0, 0);
{$ENDIF}
end;

procedure TPosixConsole.SetCursorPosition(x : integer; y : integer);
begin
{$IFDEF POSIX}
  if x < 0 then x := 0;
  if y < 0 then y := 0;
  WriteRaw(RawByteString(CSI + IntToStr(y + 1) + ';' + IntToStr(x + 1) + 'H'));
  FTrackedCursorX := x;
  FTrackedCursorY := y;
{$ENDIF}
end;

function TPosixConsole.GetCursorLeft : integer;
begin
{$IFDEF POSIX}
  result := FTrackedCursorX;
{$ELSE}
  result := 0;
{$ENDIF}
end;

procedure TPosixConsole.SetCursorLeft(value : integer);
begin
{$IFDEF POSIX}
  SetCursorPosition(value, FTrackedCursorY);
{$ENDIF}
end;

function TPosixConsole.GetCursorTop : integer;
begin
{$IFDEF POSIX}
  result := FTrackedCursorY;
{$ELSE}
  result := 0;
{$ENDIF}
end;

procedure TPosixConsole.SetCursorTop(value : integer);
begin
{$IFDEF POSIX}
  SetCursorPosition(FTrackedCursorX, value);
{$ENDIF}
end;

function TPosixConsole.GetCursorSize : integer;
begin
{$IFDEF POSIX}
  result := FCursorSize;
{$ELSE}
  result := 25;
{$ENDIF}
end;

procedure TPosixConsole.SetCursorSize(value : integer);
{$IFDEF POSIX}
var
  shape : Integer;
{$ENDIF}
begin
{$IFDEF POSIX}
  if value < 1 then value := 1;
  if value > 100 then value := 100;
  FCursorSize := value;
  // Map 1..100 to DECSCUSR shapes: small => underline(3), medium => block(1), large => block(2).
  if value <= 25 then
    shape := 3
  else if value <= 75 then
    shape := 1
  else
    shape := 2;
  WriteRaw(RawByteString(CSI + IntToStr(shape) + ' q'));
{$ENDIF}
end;

function TPosixConsole.GetCursorVisible : boolean;
begin
{$IFDEF POSIX}
  result := FCursorVisible;
{$ELSE}
  result := true;
{$ENDIF}
end;

procedure TPosixConsole.SetCursorVisible(value : boolean);
begin
{$IFDEF POSIX}
  FCursorVisible := value;
  if value then
    WriteRaw(RawByteString(CSI + '?25h'))
  else
    WriteRaw(RawByteString(CSI + '?25l'));
{$ENDIF}
end;

function TPosixConsole.GetTitle : string;
begin
{$IFDEF POSIX}
  result := FCachedTitle;
{$ELSE}
  result := '';
{$ENDIF}
end;

procedure TPosixConsole.SetTitle(const value : string);
{$IFDEF POSIX}
var
  bytes   : TBytes;
  titleBs : TBytes;
  i       : Integer;
  offset  : Integer;
{$ENDIF}
begin
{$IFDEF POSIX}
  FCachedTitle := value;
  titleBs := TEncoding.UTF8.GetBytes(value);
  SetLength(bytes, 4 + Length(titleBs) + 1);
  bytes[0] := Ord(#27);
  bytes[1] := Ord(']');
  bytes[2] := Ord('0');
  bytes[3] := Ord(';');
  offset := 4;
  for i := 0 to High(titleBs) do
  begin
    bytes[offset] := titleBs[i];
    Inc(offset);
  end;
  bytes[offset] := 7; // BEL
  WriteRaw(bytes);
{$ENDIF}
end;

function TPosixConsole.GetIsErrorRedirected : boolean;
begin
{$IFDEF POSIX}
  result := isatty(FStdErr) = 0;
{$ELSE}
  result := false;
{$ENDIF}
end;

function TPosixConsole.GetIsInputRedirected : boolean;
begin
{$IFDEF POSIX}
  result := isatty(FStdIn) = 0;
{$ELSE}
  result := false;
{$ENDIF}
end;

function TPosixConsole.GetIsOutputRedirected : boolean;
begin
{$IFDEF POSIX}
  result := isatty(FStdOut) = 0;
{$ELSE}
  result := false;
{$ENDIF}
end;

function TPosixConsole.GetConsoleOutputEncoding : TEncoding;
begin
{$IFDEF POSIX}
  if FOutputEncoding = nil then
    FOutputEncoding := TEncoding.UTF8;
  result := FOutputEncoding;
{$ELSE}
  result := TEncoding.Default;
{$ENDIF}
end;

procedure TPosixConsole.SetConsoleOutputEncoding(const value : TEncoding);
begin
{$IFDEF POSIX}
  if (FOutputEncoding <> nil) and (not TEncoding.IsStandardEncoding(FOutputEncoding)) then
    FreeAndNil(FOutputEncoding);
  if TEncoding.IsStandardEncoding(value) then
    FOutputEncoding := value
  else if value <> nil then
    FOutputEncoding := value.Clone
  else
    FOutputEncoding := TEncoding.UTF8;
{$ENDIF}
end;

function TPosixConsole.GetConsoleInputEncoding : TEncoding;
begin
{$IFDEF POSIX}
  if FInputEncoding = nil then
    FInputEncoding := TEncoding.UTF8;
  result := FInputEncoding;
{$ELSE}
  result := TEncoding.Default;
{$ENDIF}
end;

procedure TPosixConsole.SetConsoleInputEncoding(const value : TEncoding);
begin
{$IFDEF POSIX}
  if (FInputEncoding <> nil) and (not TEncoding.IsStandardEncoding(FInputEncoding)) then
    FreeAndNil(FInputEncoding);
  if TEncoding.IsStandardEncoding(value) then
    FInputEncoding := value
  else if value <> nil then
    FInputEncoding := value.Clone
  else
    FInputEncoding := TEncoding.UTF8;
{$ENDIF}
end;

function TPosixConsole.GetWindowSize : TSize;
{$IFDEF POSIX}
var
  cols : Integer;
  rows : Integer;
{$ENDIF}
begin
{$IFDEF POSIX}
  if GetWinSize(cols, rows) then
  begin
    result.Width  := cols;
    result.Height := rows;
  end
  else
  begin
    result.Width  := 80;
    result.Height := 24;
  end;
{$ELSE}
  result.Width  := 80;
  result.Height := 24;
{$ENDIF}
end;

procedure TPosixConsole.SetWindowSize(const width : integer; height : integer);
begin
{$IFDEF POSIX}
  // xterm DECSLPP: ESC[8;rows;colst  (best-effort; tmux/ssh may ignore).
  WriteRaw(RawByteString(CSI + '8;' + IntToStr(height) + ';' + IntToStr(width) + 't'));
{$ENDIF}
end;

function TPosixConsole.GetWindowPosition : TPoint;
begin
{$IFDEF POSIX}
  // Querying via ESC[13t is flaky; return origin by default (best-effort).
  result := TPoint.Create(0, 0);
{$ELSE}
  result := TPoint.Create(0, 0);
{$ENDIF}
end;

procedure TPosixConsole.SetWindowPosition(Left : integer; Top : integer);
begin
{$IFDEF POSIX}
  // xterm move-window: ESC[3;x;yt  (best-effort; often disabled).
  WriteRaw(RawByteString(CSI + '3;' + IntToStr(Left) + ';' + IntToStr(Top) + 't'));
{$ENDIF}
end;

function TPosixConsole.GetLargestWindowHeight : integer;
begin
  result := GetWindowSize.Height;
end;

function TPosixConsole.GetLargestWindowWidth : integer;
begin
  result := GetWindowSize.Width;
end;

function TPosixConsole.GetCancelKeyPress : TConsoleCancelEventHandler;
begin
{$IFDEF POSIX}
  result := FCancelKeyPress;
{$ELSE}
  result := nil;
{$ENDIF}
end;

procedure TPosixConsole.SetCancelKeyPress(value : TConsoleCancelEventHandler);
{$IFDEF POSIX}
var
  fds      : array[0..1] of Int32;
  wasAssigned : Boolean;
{$ENDIF}
begin
{$IFDEF POSIX}
  wasAssigned := Assigned(FCancelKeyPress);
  FCancelKeyPress := value;

  if not Assigned(value) then
  begin
    if wasAssigned then
      TearDownCancelHandler;
    exit;
  end;

  if FSignalDispatcher = nil then
  begin
    if pipe(fds) <> 0 then
      exit;
    FSignalDispatcher := TPosixSignalDispatcher.Create(Self, fds[0], fds[1]);
    Posix.Signal.signal(SIGINT_VAL, _PosixSigIntHandler);
  end;
  FSignalDispatcher.SetHandler(value);
{$ENDIF}
end;

procedure TPosixConsole.Beep(frequency : Cardinal; duration : Cardinal);
begin
  // POSIX terminals have no frequency/duration control. Ignore params.
  Beep;
end;

procedure TPosixConsole.Beep;
{$IFDEF POSIX}
var
  b : Byte;
{$ENDIF}
begin
{$IFDEF POSIX}
  b := 7;
  __write(FStdOut, @b, 1);
{$ENDIF}
end;

procedure TPosixConsole.Clear;
begin
{$IFDEF POSIX}
  WriteRaw(RawByteString(CSI + '2J' + CSI + 'H'));
  FTrackedCursorX := 0;
  FTrackedCursorY := 0;
{$ENDIF}
end;

function TPosixConsole.GetKeyAvailable : boolean;
begin
{$IFDEF POSIX}
  EnsureRawMode;
  result := WaitForInput(0);
{$ELSE}
  result := false;
{$ENDIF}
end;

function TPosixConsole.ReadKey(intercept : boolean) : TConsoleKeyInfo;
{$IFDEF POSIX}
var
  b    : Byte;
  next : Byte;
  info : TConsoleKeyInfo;
  ch   : Char;
{$ENDIF}
begin
{$IFDEF POSIX}
  if isatty(FStdIn) = 0 then
    raise EInvalidOperation.Create('Cannot read key when stdin is redirected');

  MonitorEnter(FReadKeySyncObject);
  try
    EnsureRawMode;
    if not ReadByteBlocking(b) then
      raise EInvalidOperation.Create('Failed to read from stdin');

    if b = 27 then
    begin
      // Possible escape sequence. Peek with short timeout.
      if not WaitForInput(50) then
      begin
        // Bare Escape
        result := TConsoleKeyInfo.Create(#27, TConsoleKey.Escape, false, false, false);
        if not intercept then
          WriteString(#27);
        exit;
      end;
      if not ReadByteBlocking(next) then
      begin
        result := TConsoleKeyInfo.Create(#27, TConsoleKey.Escape, false, false, false);
        exit;
      end;
      if next = Ord('[') then
      begin
        if ParseCsiSequence(info) then
        begin
          result := info;
          exit;
        end;
        // Parse failed; surface as Escape.
        result := TConsoleKeyInfo.Create(#27, TConsoleKey.Escape, false, false, false);
        exit;
      end;
      if next = Ord('O') then
      begin
        if ParseSs3Sequence(info) then
        begin
          result := info;
          exit;
        end;
        result := TConsoleKeyInfo.Create(#27, TConsoleKey.Escape, false, false, false);
        exit;
      end;
      // ESC + printable => Alt+<char>
      if next >= 32 then
      begin
        ch := Char(next);
        if (next >= Ord('a')) and (next <= Ord('z')) then
          result := TConsoleKeyInfo.Create(ch, TConsoleKey(next - 32), false, true, false)
        else if (next >= Ord('A')) and (next <= Ord('Z')) then
          result := TConsoleKeyInfo.Create(ch, TConsoleKey(next), true, true, false)
        else if (next >= Ord('0')) and (next <= Ord('9')) then
          result := TConsoleKeyInfo.Create(ch, TConsoleKey(next), false, true, false)
        else
          result := TConsoleKeyInfo.Create(ch, TConsoleKey.None, false, true, false);
        exit;
      end;
      // Unknown ESC+<ctrl>; bounce as Escape and push back.
      PushbackBytes([next]);
      result := TConsoleKeyInfo.Create(#27, TConsoleKey.Escape, false, false, false);
      exit;
    end;

    if b < 128 then
    begin
      result := MapControlChar(b);
      if (not intercept) and (result.KeyChar <> #0) and (result.KeyChar >= #32) then
        WriteString(string(result.KeyChar));
      exit;
    end;

    // UTF-8 multibyte sequence.
    if DecodeUtf8Char(b, ch) then
    begin
      result := TConsoleKeyInfo.Create(ch, TConsoleKey.None, false, false, false);
      if not intercept then
        WriteString(string(ch));
      exit;
    end;

    // Fallback
    result := TConsoleKeyInfo.Create(Char(b), TConsoleKey.None, false, false, false);
  finally
    MonitorExit(FReadKeySyncObject);
  end;
{$ELSE}
  result := TConsoleKeyInfo.Create(#0, TConsoleKey.None, false, false, false);
{$ENDIF}
end;

function TPosixConsole.GetCapsLock : boolean;
begin
  // Not queryable from a POSIX TTY.
  result := false;
end;

function TPosixConsole.GetNumLock : boolean;
begin
  // Not queryable from a POSIX TTY.
  result := false;
end;

function TPosixConsole.GetTreatControlCAsInput : boolean;
begin
{$IFDEF POSIX}
  result := FTreatControlCAsInput;
{$ELSE}
  result := false;
{$ENDIF}
end;

procedure TPosixConsole.SetTreatControlCAsInput(value : boolean);
begin
{$IFDEF POSIX}
  if FTreatControlCAsInput = value then
    exit;
  FTreatControlCAsInput := value;
  if FIsRawMode then
    ApplyTermiosMode;
{$ENDIF}
end;

{$IFDEF POSIX}
initialization

finalization
  if _instance <> nil then
  begin
    if _instance.FTermiosSaved then
      tcsetattr(_instance.FStdIn, TCSANOW, _instance.FOriginalTermios);
  end;
{$ENDIF}

end.
