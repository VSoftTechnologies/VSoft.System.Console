unit System.Console.Windows;

interface

//{$I 'System.Console.inc' }


uses
  WinApi.Windows,
  System.SysUtils,
  System.Classes,
  System.Console.Types,
  System.Console.InternalTypes,
  System.Console.ConsoleStream;

type
  TWindowsColor = (
    Black = $00,
    BackgroundBlue = $10,
    BackgroundGreen = $20,
    BackgroundRed = $40,
    BackgroundYellow = $60,
    BackgroundIntensity = $80,
    BackgroundMask = $F0,

    ColorMask = $FF,

    ForegroundBlue = 1,
    ForegroundGreen = 2,
    ForegroundRed = 4,
    ForegroundYellow = 6,
    ForegroundIntensity = 8,
    ForegroundMask = 15
    );

  TWindowsConsole = class(TConsoleImplementation)
  private
    FStdOut : THandle;
    FStdErr : THandle;
    FStdIn : THandle;
    FInitialTextAttributes : word;
    FCurrentTextAttributes : word;
    FSavedTextAttributes : word;
    FTextWindow : TRect;

    FOutputEncoding : TEncoding;
    FInputEncoding : TEncoding;

    FReadKeySyncObject : TObject;
    FCachedInputRecord : INPUT_RECORD;

    FCancelKeyPress : TConsoleCancelEventHandler;

    function IsReadKeyEvent(ir : PInputRecord) : boolean;
  protected
    function ConsoleHandleIsWritable(outErrHandle : THandle) : boolean;
    function GetStandardFile(handleType : DWORD; fileAccess : TFileAccess; useFileAPIs : boolean) : TStream;

    function PlatformName : string; override;

    function ConsoleCursorInfo : TConsoleCursorInfo;

    function GetBufferInfo : TConsoleScreenBufferInfo;
    function TryGetBufferInfo(var info : TConsoleScreenBufferInfo) : boolean;
    procedure EnsureConsole;
    function IsHandleRedirected(handle : THandle) : boolean;
    procedure WriteString(const value : string); override;
    procedure SetTempColors(foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet); override;
    procedure RestoreColors; override;
    function ConsoleColorToColorAttribute(consoleColor : TConsoleColor; isBackground : boolean) : TWindowsColor;

    function GetConsoleBounds : TRect;
    procedure SetConsoleBounds(value : TRect);

    function ConsoleCtrlHandler(dwCtrlType : DWORD) : bool;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetColors(foreground : TConsoleColor; background : TConsoleColor); override;
    procedure ResetColors; override;

    function GetBackgroundColor : TConsoleColor; override;
    procedure SetBackgroundColor(value : TConsoleColor); override;
    function GetForegroundColor : TConsoleColor; override;
    procedure SetForegroundColor(value : TConsoleColor); override;

    function GetBufferWidth : integer; override;
    procedure SetBufferWidth(value : integer); override;

    function GetBufferHeight : integer; override;
    procedure SetBufferHeight(value : integer); override;

    procedure SetBufferSize(width : integer; height : integer); override;

    function GetCursorPosition : TPoint;override;
    procedure SetCursorPosition(x : integer; y : integer); override;

    function GetCursorLeft : integer; override;
    procedure SetCursorLeft(value : integer); override;

    function GetCursorTop : integer; override;
    procedure SetCursorTop(value : integer); override;

    function GetCursorSize : integer; override;
    procedure SetCursorSize(value : integer); override;

    function GetCursorVisible : boolean;override;
    procedure SetCursorVisible(value : boolean);override;

    function GetTitle : string; override;
    procedure SetTitle(const value : string); override;

    function OpenStandardInput : TStream; override;
    function OpenStandardOutput : TStream; override;
    function OpenStandardError : TStream; override;

    function GetOrCreateReader : TTextReader; override;

    function GetConsoleOutputEncoding : TEncoding; override;
    procedure SetConsoleOutputEncoding(const value : TEncoding); override;
    function GetConsoleInputEncoding : TEncoding; override;
    procedure SetConsoleInputEncoding(const value : TEncoding); override;

    function GetWindowSize : TSize; override;
    procedure SetWindowSize(const width : integer; height : integer); override;

    function GetLargestWindowHeight : integer;override;
    function GetLargestWindowWidth : integer;override;

    function GetWindowPosition : TPoint; override;
    procedure SetWindowPosition(Left, Top: integer);override;

    function GetCancelKeyPress : TConsoleCancelEventHandler;override;
    procedure SetCancelKeyPress(value : TConsoleCancelEventHandler);override;

    procedure Beep(frequency : Cardinal; duration : Cardinal); override;
    procedure Beep; override;

    procedure Clear; override;

    procedure MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop : integer); override;
    procedure MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop : integer; sourceChar : Char; sourceForeColor, sourceBackColor : TConsoleColor); override;

    function GetKeyAvailable : boolean;override;
    function ReadKey(intercept : boolean) : TConsoleKeyInfo; override;

    function GetIsErrorRedirected  : boolean; override;
    function GetIsInputRedirected  : boolean; override;
    function GetIsOutputRedirected : boolean; override;
    function GetKey(code : integer) : boolean;
    function GetCapsLock : boolean; override;
    function GetNumLock  : boolean; override;
    function GetTreatControlCAsInput: boolean;override;
    procedure SetTreatControlCAsInput(value : boolean);override;


  end;

  TWindowsConsoleStream = class(TConsoleStream)
  private
  // We know that if we are using console APIs rather than file APIs, then the encoding
  // is Encoding.Unicode implying 2 bytes per character:
    const
    BytesPerWChar : DWORD = 2;
  private
    FUseFileAPIs : boolean;
  public
    constructor Create(handle : THandle; access : TFileAccess; useFileAPIs : boolean);
    function Read(var Buffer; Count : Longint) : Longint; override;
    function Write(const Buffer; Count : Longint) : Longint; override;
  end;

const
  RightAltPressed = $0001;
  LeftAltPressed = $0002;
  RightCtrlPressed = $0004;
  LeftCtrlPressed = $0008;
  ShiftPressed = $0010;
  NumLockOn = $0020;
  ScrollLockOn = $0040;
  CapsLockOn = $0080;
  EnhancedKey = $0100;

implementation

uses
  System.Rtti,
  System.SyncObjs,
  System.Console, System.Console.SyncTextReader;

{$IFNDEF 10_4UP }
function AttachConsole(dwProcessId : DWORD) : Bool; stdcall; external KERNEL32 name 'AttachConsole';
function GetConsoleWindow : THandle; stdcall; external kernel32 name 'GetConsoleWindow';

const
  ATTACH_PARENT_PROCESS = DWORD(-1);
{$EXTERNALSYM ATTACH_PARENT_PROCESS}

{$ENDIF}

var
  _instance : TWindowsConsole;

const
  MaxShort = 32767;

function _ConsoleCtrlHandler(dwCtrlType : DWORD) : bool;stdcall;
begin
  result := false;
  if Assigned(_instance) then
    result := _instance.ConsoleCtrlHandler(dwCtrlType);
end;


procedure TWindowsConsole.Beep;
// const
// BellString = '\u0007'; // Windows doesn't use terminfo, so the codepoint is hardcoded.
// var
// bell : TBytes;
// numBytesWritten : Cardinal;
// writeSuccess : boolean;
// lastError : Cardinal;
begin
  // This doesn't seem to work so far in testing - not sure if it does in dotnet
  // if (not GetIsOutputRedirected) then
  // begin
  // bell := FOutputEncoding.GetBytes(BellString);
  // if FOutputEncoding.CodePage <> TEncoding.Unicode.CodePage then
  // writeSuccess := WinApi.Windows.WriteFile(FStdOut, bell, Length(bell), numBytesWritten,nil);
  // else
  // writeSuccess := WinApi.Windows.WriteConsole(FStdOut, @bell[0], Length(bell) div 2,  numBytesWritten,nil );
  // if not writeSuccess then
  // begin
  // lastError := GetLastError;
  // if (lastError = ERROR_SUCCESS) or (lastError = ERROR_NO_DATA) or (lastError = ERROR_BROKEN_PIPE) or (lastError = ERROR_PIPE_NOT_CONNECTED) then
  // exit;
  // //fallback if terminal bell didn't work.
  //
  // end
  // else
  // exit;
  // end;
  Beep(800, 200);
end;

procedure TWindowsConsole.Beep(frequency, duration : Cardinal);
const
  MinBeepFrequency = 37;
  MaxBeepFrequency = 32767;
begin
  if (frequency < MinBeepFrequency) or (frequency > MaxBeepFrequency) then
    raise EArgumentOutOfRangeException.Create('Frequency out of range : 37 - 32767hz');

  WinApi.Windows.Beep(frequency, duration);
end;

procedure TWindowsConsole.Clear;
var
  startPos : TCoord;
  Buffer : TConsoleScreenBufferInfo;
  conSize : integer;
  numWritten : DWORD;

begin
  if FStdOut = INVALID_HANDLE_value then
    exit;

  // get the number of character cells in the current buffer
  // Go through my helper method for fetching a screen buffer info
  // to correctly handle default console colors.
  Buffer := GetBufferInfo;
  conSize := Buffer.dwSize.x * Buffer.dwSize.y;
  startPos.x := 0;
  startPos.y := 0;

  // fill the entire screen with blanks
  if not FillConsoleOutputCharacter(FStdOut, ' ', conSize, startPos, numWritten) then
    raise EOSError.Create('FillConsoleOutputCharacter');

  numWritten := 0;
  // now set the buffer's attributes accordingly
  if not FillConsoleOutputAttribute(FStdOut, Buffer.wAttributes, conSize, startPos, numWritten) then
    raise EOSError.Create('FillConsoleOutputAttribute');

  // put the Cursor at (0, 0)
  SetConsoleCursorPosition(FStdOut, startPos);

end;

function TWindowsConsole.ConsoleCursorInfo : TConsoleCursorInfo;
begin
  if not GetConsoleCursorInfo(FStdOut, Result) then
    RaiseLastOSError;
end;

constructor TWindowsConsole.Create;
begin
  inherited;
  _instance := self; //total hack for SetConsoleCtrlHandler;
  FReadKeySyncObject := TObject.Create;
  // Note - if no console is allocated these could return INVALID_HANDLE_value
  FStdIn := GetStdHandle(STD_INPUT_HANDLE);
  FStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  FStdErr := GetStdHandle(STD_ERROR_HANDLE);

  EnsureConsole;

end;

destructor TWindowsConsole.Destroy;
begin
  FreeAndNil(FReadKeySyncObject);

  inherited;
end;

procedure TWindowsConsole.EnsureConsole;
var
  bufferInfo : TConsoleScreenBufferInfo;
begin
  // first try attach to the parent process's console
  if not AttachConsole(ATTACH_PARENT_PROCESS) then
    AllocConsole; // this fails and we are ignore it.

  // if we got here we either have the parent process or our own console so fetch the handles again.
  FStdIn := GetStdHandle(STD_INPUT_HANDLE);
  FStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  FStdErr := GetStdHandle(STD_ERROR_HANDLE);

  if not GetConsoleScreenBufferInfo(FStdOut, bufferInfo) then
  begin
    // set IOResult;
    SetInOutRes(GetLastError);
    exit;
  end;

  FInitialTextAttributes := bufferInfo.wAttributes and $FF;
  FCurrentTextAttributes := FInitialTextAttributes;
  FTextWindow := TRect.Create(0, 0, bufferInfo.dwSize.x - 1, bufferInfo.dwSize.y - 1);
  // force creation
  GetConsoleInputEncoding;
  GetConsoleOutputEncoding;

end;

function TWindowsConsole.GetBackgroundColor : TConsoleColor;
begin
  Result := TConsoleColor((FCurrentTextAttributes and $0F) shr 4);
end;

function TWindowsConsole.GetBufferHeight : integer;
begin
  Result := GetBufferInfo.dwSize.y;
end;

function TWindowsConsole.GetBufferInfo : TConsoleScreenBufferInfo;
begin
  if not TryGetBufferInfo(Result) then
    RaiseLastOSError;
end;

function TWindowsConsole.GetBufferWidth : integer;
begin
  Result := GetBufferInfo.dwSize.x;
end;

function TWindowsConsole.GetCursorLeft : integer;
begin
  Result := GetBufferInfo.dwCursorPosition.x
end;

function TWindowsConsole.GetCursorPosition: TPoint;
var
  info : TConsoleScreenBufferInfo;
begin
  info := GetBufferInfo;
  result := TPoint.Create(info.dwCursorPosition.X, info.dwCursorPosition.Y);
end;

function TWindowsConsole.GetCursorSize : integer;
begin
  Result := ConsoleCursorInfo.dwSize;
end;

function TWindowsConsole.GetCursorTop : integer;
begin
  Result := GetBufferInfo.dwCursorPosition.y
end;

function TWindowsConsole.GetCursorVisible : boolean;
begin
  Result := ConsoleCursorInfo.bVisible;
end;

function TWindowsConsole.GetForegroundColor : TConsoleColor;
begin
  Result := TConsoleColor(FCurrentTextAttributes and $0F);
end;

function TWindowsConsole.GetCancelKeyPress: TConsoleCancelEventHandler;
begin
  result := FCancelKeyPress;
end;

function TWindowsConsole.GetCapsLock: boolean;
begin
  result := GetKey(VK_CAPITAL)
end;

function TWindowsConsole.GetConsoleBounds: TRect;
begin
  ZeroMemory(@result, SizeOf(TRect));
  GetWindowRect(GetConsoleWindow, result);
end;

function TWindowsConsole.GetConsoleInputEncoding : TEncoding;
var
  CP : UInt;
  enc : TEncoding;
begin
  if FInputEncoding = nil then
  begin
    CP := GetConsoleCP;
    enc := TEncoding.GetEncoding(CP);
    if TInterlocked.CompareExchange(Pointer(FInputEncoding), Pointer(enc), nil) <> nil then
      // The other beat us. Destroy our newly created object and use theirs.
      enc.Free;
  end;
  Result := FInputEncoding;
end;

function TWindowsConsole.GetIsErrorRedirected : boolean;
begin
  Result := IsHandleRedirected(GetStdHandle(STD_ERROR_HANDLE));
end;

function TWindowsConsole.GetIsInputRedirected : boolean;
begin
  Result := IsHandleRedirected(GetStdHandle(STD_INPUT_HANDLE));
end;

function TWindowsConsole.GetIsOutputRedirected : boolean;
begin
  Result := IsHandleRedirected(GetStdHandle(STD_OUTPUT_HANDLE));
end;

function TWindowsConsole.GetKey(code: integer): boolean;
begin
  result := (GetKeyState(code) and 1) = 1 ;
end;

function TWindowsConsole.GetKeyAvailable: boolean;
var
  ir : INPUT_RECORD;
  r : boolean;
  numEventsRead : DWORD;
  errorCode : DWORD;
  ir2 : TInputRecord;
begin
  if (FCachedInputRecord.EventType = KEY_EVENT) then
    exit(true);
  while (true) do
  begin
    r := PeekConsoleInput(FStdIn, ir, 1, numEventsRead);
    if (not r) then
    begin
      errorCode := GetLastError;
      if (errorCode = ERROR_INVALID_HANDLE) then
        raise EInvalidOperation.Create('Console.KeyAvailable called on file handle');
      RaiseLastOSError(errorCode);
    end;
    if (numEventsRead = 0) then
      exit(false);

    // Skip non-significant events.
    if (not IsReadKeyEvent(@ir)) then
    begin
      r := ReadConsoleInput(FStdIn, ir2, 1, numEventsRead);
      if (not r) then
        RaiseLastOSError
      else
        exit(true);
    end;
  end;
end;

function TWindowsConsole.GetLargestWindowHeight: integer;
var
  bounds : TCoord;
begin
  bounds := GetLargestConsoleWindowSize(FStdOut);
  result := bounds.Y
end;

function TWindowsConsole.GetLargestWindowWidth: integer;
var
  bounds : TCoord;
begin
  bounds := GetLargestConsoleWindowSize(FStdOut);
  result := bounds.X;
end;

function TWindowsConsole.GetNumLock: boolean;
begin
  result := GetKey(VK_NUMLOCK);
end;

function TWindowsConsole.GetOrCreateReader : TTextReader;
var
  stream : TStream;
  reader : TStreamReader;
begin
  stream := OpenStandardInput;
  if stream = nil then
    exit(nil);
  reader := TStreamReader.Create(stream, FInputEncoding);
  reader.OwnStream;
  Result := TSyncTextReader.GetSynchronizedTextReader(reader)
end;

function TWindowsConsole.GetConsoleOutputEncoding : TEncoding;
var
  CP : UInt;
  enc : TEncoding;
begin
  if FOutputEncoding = nil then
  begin
    CP := GetConsoleOutputCP;
    enc := TEncoding.GetEncoding(CP);
    if TInterlocked.CompareExchange(Pointer(FOutputEncoding), Pointer(enc), nil) <> nil then
      // The other beat us. Destroy our newly created object and use theirs.
      enc.Free;
  end;
  Result := FOutputEncoding;
end;

// Checks whether stdout or stderr are writable.  Do NOT pass
// stdin here! The console handles are set to values like 3, 7,
// and 11 OR if you've been created via CreateProcess, possibly -1
// or 0.  -1 is definitely invalid, while 0 is probably invalid.
// Also note each handle can independently be invalid or good.
// For Windows apps, the console handles are set to values like 3, 7,
// and 11 but are invalid handles - you may not write to them.  However,
// you can still spawn a Windows app via CreateProcess and read stdout
// and stderr. So, we always need to check each handle independently for validity
// by trying to write or read to it, unless it is -1.
function TWindowsConsole.ConsoleHandleIsWritable(outErrHandle : THandle) : boolean;
var
  junkByte : byte;
  bytesWritten : DWORD;
begin
  // Windows apps may have non-null valid looking handle values for
  // stdin, stdout and stderr, but they may not be readable or
  // writable.  Verify this by calling WriteFile in the
  // appropriate modes. This must handle console-less Windows apps.
  junkByte := $41;
  Result := WinApi.Windows.WriteFile(outErrHandle, &junkByte, 0, bytesWritten, nil);
end;

function TWindowsConsole.GetStandardFile(handleType : DWORD; fileAccess : TFileAccess; useFileAPIs : boolean) : TStream;
var
  handle : THandle;
begin
  Result := nil;

  handle := GetStdHandle(handleType);

  // If someone launches a managed process via CreateProcess, stdout,
  // stderr, & stdin could independently be set to INVALID_HANDLE_value.
  // Additionally they might use 0 as an invalid handle.  We also need to
  // ensure that if the handle is meant to be writable it actually is.
  if (handle = INVALID_HANDLE_value) or ((fileAccess <> TFileAccess.Read) and (not ConsoleHandleIsWritable(handle))) then
    exit;

  Result := TWindowsConsoleStream.Create(handle, fileAccess, useFileAPIs);
end;

function TWindowsConsole.GetTitle : string;
var
  len : integer;
begin
  if GetConsoleWindow = 0 then
    exit('');

  len := GetWindowTextLength(GetConsoleWindow);
  SetLength(Result, len);
  FillChar(Result[1], len, 0);
  GetWindowText(GetConsoleWindow, PChar(Result), len + 1);
end;

function TWindowsConsole.GetTreatControlCAsInput: boolean;
var
  mode: DWORD;
begin
  Result := false;
  if FStdIn = INVALID_HANDLE_value then
    raise EInvalidOperation.Create('No console available');
  Mode := 0;

  if not GetConsoleMode(FStdIn, mode) then
    RaiseLastOSError
  else
    Result := (mode and ENABLE_PROCESSED_INPUT) = 0;
end;

function TWindowsConsole.GetWindowPosition: TPoint;
var
  r : TRect;
begin
  r := GetConsoleBounds;
  result := r.Location;
end;

function TWindowsConsole.GetWindowSize : TSize;
var
  bufferInfo : TConsoleScreenBufferInfo;
begin
  bufferInfo := GetBufferInfo;
  Result.Height := bufferInfo.srWindow.Bottom - bufferInfo.srWindow.Top + 1;
  Result.Width := bufferInfo.srWindow.Right - bufferInfo.srWindow.Left + 1;
end;

function TWindowsConsole.IsHandleRedirected(handle : THandle) : boolean;
var
  fileType : DWORD;

  function IsGetConsoleModeCallSuccessful(handle : THandle) : boolean;
  var
    mode : DWORD;
  begin
    Result := GetConsoleMode(handle, mode);
  end;

begin
  fileType := GetFileType(handle);
  // If handle is not to a character device, we must be redirected:
  if (fileType and FILE_TYPE_CHAR) <> FILE_TYPE_CHAR then
    exit(true);

  // We are on a char device if GetConsoleMode succeeds and so we are not redirected.
  Result := not IsGetConsoleModeCallSuccessful(handle);
end;

function TWindowsConsole.OpenStandardError : TStream;
var
  useFileAPIs : boolean;
begin
  useFileAPIs := (Console.InputEncoding.CodePage <> TEncoding.Unicode.CodePage) or Console.IsInputRedirected;
  Result := GetStandardFile(STD_ERROR_HANDLE, TFileAccess.Write, useFileAPIs);
end;

function TWindowsConsole.OpenStandardInput : TStream;
var
  useFileAPIs : boolean;
begin
  useFileAPIs := (Console.InputEncoding.CodePage <> TEncoding.Unicode.CodePage) or Console.IsInputRedirected;
  Result := GetStandardFile(STD_INPUT_HANDLE, TFileAccess.Read, useFileAPIs);
end;

function TWindowsConsole.OpenStandardOutput : TStream;
var
  useFileAPIs : boolean;
begin
  useFileAPIs := (Console.InputEncoding.CodePage <> TEncoding.Unicode.CodePage) or Console.IsInputRedirected;
  Result := GetStandardFile(STD_OUTPUT_HANDLE, TFileAccess.Write, useFileAPIs);
end;

function TWindowsConsole.PlatformName : string;
begin
  Result := 'Windows';
end;

// Skip non key events. Generally we want to surface only KeyDown event
// and suppress KeyUp event from the same Key press but there are cases
// where the assumption of KeyDown-KeyUp pairing for a given key press
// is invalid. For example in IME Unicode keyboard input, we often see
// only KeyUp until the key is released.
function TWindowsConsole.IsReadKeyEvent(ir : PInputRecord) : boolean;
const
  AltVKCode = $12;
var
  keyCode : word;
  keyState : DWORD;
  key : TConsoleKey;
begin
  Result := false;
  if (ir.EventType <> KEY_EVENT) then
    // Skip non key events.
    exit;
  if ir.Event.KeyEvent.bKeyDown = false then
  begin
    // The only keyup event we don't skip is Alt keyup with a synthesized unicode char,
    // which is either the result of an Alt+Numpad key sequence, an IME-generated char,
    // or a pasted char without a matching key.

    Result := (ir.Event.KeyEvent.wVirtualKeyCode = AltVKCode) and (ir.Event.KeyEvent.UnicodeChar <> #0);
    exit;

  end
  else
  begin
    // Keydown event. Some of these we need to skip as well.
    keyCode := ir.Event.KeyEvent.wVirtualKeyCode;
    if (keyCode >= $10) and (keyCode <= $12) then
      // Skip modifier keys Shift, Control, Alt.
      exit;
    if (keyCode in [$14, $90, $91]) then
      // Skip CapsLock, NumLock, and ScrollLock keys,
      exit;

    keyState := ir.Event.KeyEvent.dwControlKeyState;
    if ((keyState and (LeftAltPressed or RightAltPressed)) <> 0) then
    begin
      // Possible Alt+NumPad unicode key sequence which surfaces by a subsequent
      // Alt keyup event with uChar (see above).
      key := TConsoleKey(keyCode);
      if (key >= TConsoleKey.NumPad0) and (key <= TConsoleKey.NumPad9) then
        // Alt+Numpad keys (as received if NumLock is on).
        exit;

      // If Numlock is off, the physical Numpad keys are received as navigation or
      // function keys. The EnhancedKey flag tells us whether these virtual keys
      // really originate from the numpad, or from the arrow pad / control pad.
      if ((keyState and EnhancedKey) = 0) then
      begin
        // If the EnhancedKey flag is not set, the following virtual keys originate
        // from the numpad.
        if (key in [TConsoleKey.Clear, TConsoleKey.Insert]) then
          // Skip Clear and Insert (usually mapped to Numpad 5 and 0).
          exit;
        if (key >= TConsoleKey.PageUp) and (key <= TConsoleKey.DownArrow) then
          // Skip PageUp/Down, End/Home, and arrow keys.
          exit;
      end;
    end;
    Result := true;
  end;

end;

function TWindowsConsole.ConsoleColorToColorAttribute(consoleColor : TConsoleColor; isBackground : boolean) : TWindowsColor;
begin
  if ((integer(consoleColor) and not integer(TConsoleColor.White)) <> integer(TConsoleColor.Black)) then
    raise EArgumentException.Create('Invalid ConsoleColor');

  Result := TWindowsColor(consoleColor);

  // Make these background colors instead of foreground
  if (isBackground) then
    Result := TWindowsColor(SmallInt(integer(Result) shl 4));
end;

function TWindowsConsole.ConsoleCtrlHandler(dwCtrlType: DWORD): bool;
var
  args : TConsoleCancelEventArgs;
  key : TConsoleSpecialKey;
begin
  result := false;
  if not Assigned(FCancelKeyPress) then
    exit;

  case dwCtrlType of
    CTRL_C_EVENT : key := TConsoleSpecialKey.ControlC;
    CTRL_BREAK_EVENT : key := TConsoleSpecialKey.ControlBreak;
    CTRL_CLOSE_EVENT : key := TConsoleSpecialKey.ControlClose;

    CTRL_LOGOFF_EVENT : key := TConsoleSpecialKey.ControlLogOff;     //not sure about this, dotnet doesn't map them
    CTRL_SHUTDOWN_EVENT : key := TConsoleSpecialKey.ControlShutdown;
  else
    exit;
  end;

  args := TConsoleCancelEventArgs.Create(key);
  try
    FCancelKeyPress(Self, args);
  finally
    result := args.Cancel;
    args.Free;
  end;

end;

procedure TWindowsConsole.MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop : integer; sourceChar : Char; sourceForeColor, sourceBackColor : TConsoleColor);
var
  i : integer;
  data : array of CHAR_INFO;
  numberOfCharsWritten : DWORD;
  bufferSize : TCoord;
  readRegion, writeRegion : SMALL_RECT;
  writeCoord, bufferCoord : TCoord;
  wColorAttribute : word;
  color : TWindowsColor;
begin
  if FStdOut = INVALID_HANDLE_value then
    exit;

  if ((sourceForeColor < TConsoleColor.Black) or (sourceForeColor > TConsoleColor.White)) then
    raise EArgumentException.Create('sourceForeColor : Invalid Console Color');
  if ((sourceBackColor < TConsoleColor.Black) or (sourceBackColor > TConsoleColor.White)) then
    raise EArgumentException.Create('sourceBackColor : Invalid Console Color');

  bufferSize := GetBufferInfo.dwSize;

  if ((sourceLeft < 0) or (sourceLeft > bufferSize.x)) then
    raise EArgumentOutOfRangeException.Create('sourceLeft ' + IntToStr(sourceLeft) + ' ConsoleBufferBoundaries');
  if ((sourceTop < 0) or (sourceTop > bufferSize.y)) then
    raise EArgumentOutOfRangeException.Create('sourceTop ' + IntToStr(sourceTop) + ' ConsoleBufferBoundaries');
  if ((sourceWidth < 0) or (sourceWidth > (bufferSize.x - sourceLeft))) then
    raise EArgumentOutOfRangeException.Create('sourceWidth ' + IntToStr(sourceWidth) + ' ConsoleBufferBoundaries');
  if ((sourceHeight < 0) or (sourceTop > (bufferSize.y - sourceHeight))) then
    raise EArgumentOutOfRangeException.Create('sourceHeight ' + IntToStr(sourceHeight) + ' ConsoleBufferBoundaries');

  // Note: if the target range is partially in and partially out
  // of the buffer, then we let the OS clip it for us.
  if ((targetLeft < 0) or (targetLeft > bufferSize.x)) then
    raise EArgumentOutOfRangeException.Create('targetLeft ' + IntToStr(targetLeft) + ' ConsoleBufferBoundaries');
  if ((targetTop < 0) or (targetTop > bufferSize.y)) then
    raise EArgumentOutOfRangeException.Create('targetTop ' + IntToStr(targetTop) + ' ConsoleBufferBoundaries');

  // If we're not doing any work, bail out now (Windows will return
  // an error otherwise)
  if (sourceWidth = 0) or (sourceHeight = 0) then
    exit;

  // Read data from the original location, blank it out, then write
  // it to the new location.  This will handle overlapping source and
  // destination regions correctly.

  SetLength(data, sourceWidth * sourceHeight);
  bufferSize.x := SHORT(sourceWidth);
  bufferSize.y := SHORT(sourceHeight);
  readRegion.Left := SHORT(sourceLeft);
  readRegion.Right := SHORT((sourceLeft + sourceWidth) - 1);
  readRegion.Top := SHORT(sourceTop);
  readRegion.Bottom := SHORT((sourceTop + sourceHeight) - 1);

  bufferCoord.x := 0;
  bufferCoord.y := 0;

  //read the old section
  if (not ReadConsoleOutput(FStdOut, @data[0], bufferSize, bufferCoord, readRegion)) then
    RaiseLastOSError;

  // Overwrite old section
  writeCoord.y := 0;
  writeCoord.x := smallInt(sourceLeft);
  color := ConsoleColorToColorAttribute(sourceBackColor, true);
  color := TWindowsColor(integer(color) or integer(ConsoleColorToColorAttribute(sourceForeColor, false)));
  wColorAttribute := word(color);
  i := sourceTop;

  while (i < (sourceTop + sourceHeight)) do
  begin
    writeCoord.y := SmallInt(i);
    if (not FillConsoleOutputCharacter(FStdOut, sourceChar, sourceWidth, writeCoord, numberOfCharsWritten)) then
      RaiseLastOSError;
    if (not FillConsoleOutputAttribute(FStdOut, wColorAttribute, sourceWidth, writeCoord, numberOfCharsWritten)) then
      RaiseLastOSError;
    Inc(i)
  end;

 // Write text to new location
  writeRegion.Left := targetLeft;
  writeRegion.Right := targetLeft + sourceWidth;
  writeRegion.Top := targetTop;
  writeRegion.Bottom := targetTop + sourceHeight;

  if not WriteConsoleOutput(FStdOut, @data[0], bufferSize, bufferCoord, writeRegion) then
    RaiseLastOSError;

end;

procedure TWindowsConsole.MoveBufferArea(const sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop : integer);
begin
  MoveBufferArea(sourceLeft, sourceTop, sourceWidth, sourceHeight, targetLeft, targetTop, ' ', TConsoleColor.Black, GetBackgroundColor)
end;

function TWindowsConsole.ReadKey(intercept : boolean) : TConsoleKeyInfo;
var
  ir : INPUT_RECORD;
  r : boolean;
  numEventsRead : DWORD;
  keyState : DWORD;
  shift, alt, control : boolean;
begin

  // Use this for blocking in Console.ReadKey, which needs to protect itself in case multiple threads call it simultaneously.
  // Use a ReadKey-specific lock though, to allow other fields to be initialized on this type.
  MonitorEnter(Self);
  try
    if (FCachedInputRecord.EventType = KEY_EVENT) then
    begin
      // We had a previous keystroke with repeated characters.
      ir := FCachedInputRecord;
      if (FCachedInputRecord.Event.KeyEvent.wRepeatCount = 0) then
        FCachedInputRecord.EventType := 0
      else
        FCachedInputRecord.Event.KeyEvent.wRepeatCount := FCachedInputRecord.Event.KeyEvent.wRepeatCount - 1;
      // We will return one key from this method, so we decrement the
      // repeatCount here, leaving the cachedInputRecord in the "queue".
    end
    else
    begin
      // We did NOT have a previous keystroke with repeated characters:
      while true do
      begin
        r := ReadConsoleInput(FStdIn, ir, 1, numEventsRead);
        if not r then
          // This will fail when stdin is redirected from a file or pipe.
          // We could theoretically call Console.Read here, but I
          // think we might do some things incorrectly then.
          raise EInvalidOperation.Create('Cannot read key from file');
        if (numEventsRead = 0) then
          continue;
        // This can happen when there are multiple console-attached
        // processes waiting for input, and another one is terminated
        // while we are waiting for input.
        //
        // (This is "almost certainly" a bug, but behavior has been
        // this way for a long time, so we should handle it:
        // https://github.com/microsoft/terminal/issues/15859)
        //
        // (It's a rare case to have multiple console-attached
        // processes waiting for input, but it can happen sometimes,
        // such as when ctrl+c'ing a build process that is spawning
        // tons of child processes--sometimes, due to the order in
        // which processes exit, a managed shell process (like pwsh)
        // might get back to the prompt and start trying to read input
        // while there are still child processes getting cleaned up.)
        //
        // In this case, we just need to retry the read.

        if (not IsReadKeyEvent(@ir)) then
          continue;

        if (ir.Event.KeyEvent.wRepeatCount > 1) then
        begin
          ir.Event.KeyEvent.wRepeatCount := ir.Event.KeyEvent.wRepeatCount - 1;
          FCachedInputRecord := ir;
        end;
        break;

      end;
    end;
  finally
    MonitorExit(Self);
  end;

  keyState := ir.Event.KeyEvent.dwControlKeyState;
  shift := (keyState and ShiftPressed) <> 0;
  alt := (keyState and (LeftAltPressed or RightAltPressed)) <> 0;
  control := (keyState and (LeftCtrlPressed or RightCtrlPressed)) <> 0;
  Result := TConsoleKeyInfo.Create(ir.Event.KeyEvent.UnicodeChar, TConsoleKey(ir.Event.KeyEvent.wVirtualKeyCode), shift, alt, control);

  if not intercept then
    Console.Write(ir.Event.KeyEvent.UnicodeChar);

end;

procedure TWindowsConsole.ResetColors;
begin
  FCurrentTextAttributes := FInitialTextAttributes;
  SetConsoleTextAttribute(FStdOut, FCurrentTextAttributes);
end;

procedure TWindowsConsole.RestoreColors;
begin
  FCurrentTextAttributes := FSavedTextAttributes;
  SetConsoleTextAttribute(FStdOut, FCurrentTextAttributes);
end;

procedure TWindowsConsole.SetBackgroundColor(value : TConsoleColor);
begin
  FCurrentTextAttributes := (FCurrentTextAttributes and $0F) or ((word(value) shl 4) and $F0);
  SetConsoleTextAttribute(FStdOut, FCurrentTextAttributes);
end;

procedure TWindowsConsole.SetBufferHeight(value : integer);
var
  coord : TCoord;
begin
  coord.x := GetBufferWidth;
  coord.y := value;
  if not SetConsoleScreenBufferSize(FStdOut, coord) then
    RaiseLastOSError;
end;

procedure TWindowsConsole.SetBufferSize(width, height : integer);
var
  coord : TCoord;
begin
  coord.x := width;
  coord.y := height;
  if not SetConsoleScreenBufferSize(FStdOut, coord) then
    RaiseLastOSError;
end;

procedure TWindowsConsole.SetBufferWidth(value : integer);
var
  coord : TCoord;
begin
  coord.x := value;
  coord.y := GetBufferHeight;
  SetConsoleScreenBufferSize(FStdOut, coord);
end;

procedure TWindowsConsole.SetCursorPosition(x, y : integer);
var
  pt : TPoint;
  coord : TCoord;
begin
  pt.x := x + FTextWindow.Left;
  pt.y := y + FTextWindow.Top ;
  if PtInRect(FTextWindow, pt) then
  begin
    coord.x := Short(pt.x);
    coord.y := Short(pt.y);
    if not SetConsoleCursorPosition(FStdOut, coord) then
      RaiseLastOSError;
  end;
end;

procedure TWindowsConsole.SetCursorSize(value : integer);
var
  cursorInfo : TConsoleCursorInfo;
begin
  if ((value < 1) or (value > 100)) then
    raise EArgumentOutOfRangeException.Create('CursorSize : ' + IntToStr(value) + ' out of range (1-100)');

  cursorInfo := ConsoleCursorInfo;
  cursorInfo.dwSize := value;

  if (not SetConsoleCursorInfo(FStdOut, cursorInfo)) then
    RaiseLastOSError;

end;

procedure TWindowsConsole.SetCancelKeyPress(value: TConsoleCancelEventHandler);
var
  wasAssigned : boolean;
begin
  wasAssigned := Assigned(FCancelKeyPress);

  if not Assigned(value) then
  begin
    FCancelKeyPress := value;
    if wasAssigned then
    begin
      //unhook event
      if not SetConsoleCtrlHandler(nil, false) then
        RaiseLastOSError;
    end;
    exit;
  end;

  FCancelKeyPress := value;
  if not wasAssigned then
  begin
    //hook event
    if not SetConsoleCtrlHandler(@_ConsoleCtrlHandler, true) then
      RaiseLastOSError;

  end;
end;

procedure TWindowsConsole.SetColors(foreground, background : TConsoleColor);
begin
  FCurrentTextAttributes := (FCurrentTextAttributes and $F0) or (word(foreground) and $0F);
  if background <> TConsoleColor.NotSet then
    FCurrentTextAttributes := (FCurrentTextAttributes and $0F) or ((word(background) shl 4) and $F0);
  SetConsoleTextAttribute(FStdOut, FCurrentTextAttributes);
end;

procedure TWindowsConsole.SetCursorLeft(value : integer);
begin
  SetCursorPos(value, GetCursorTop);
end;

procedure TWindowsConsole.SetCursorTop(value : integer);
begin
  SetCursorPos(GetCursorLeft, value);
end;

procedure TWindowsConsole.SetCursorVisible(value : boolean);
var
  cursorInfo : TConsoleCursorInfo;
begin
  cursorInfo := ConsoleCursorInfo;
  cursorInfo.bVisible := value;

  if (not SetConsoleCursorInfo(FStdOut, cursorInfo)) then
    RaiseLastOSError;
end;

procedure TWindowsConsole.SetForegroundColor(value : TConsoleColor);
begin
  FCurrentTextAttributes := (FCurrentTextAttributes and $F0) or (word(value) and $0F);
  SetConsoleTextAttribute(FStdOut, FCurrentTextAttributes);
end;

procedure HandleSetConsoleEncodingError(lastError : integer);
begin
  if (lastError = ERROR_INVALID_HANDLE) or (lastError = ERROR_INVALID_ACCESS) then
    exit; // no console, or not a valid handle, so fail silently
  RaiseLastOSError(lastError);
end;

procedure TWindowsConsole.SetConsoleBounds(value: TRect);
begin
  SetWindowPos(GetConsoleWindow, 0, value.Left, value.Top, value.Right, value.Bottom, SWP_SHOWWINDOW);
end;

procedure TWindowsConsole.SetConsoleInputEncoding(const value : TEncoding);
begin
  if not TEncoding.IsStandardEncoding(FInputEncoding) then
    FInputEncoding.Free;
  if TEncoding.IsStandardEncoding(value) then
    FInputEncoding := value
  else if value <> nil then
    FInputEncoding := value.Clone
  else
    FInputEncoding := TEncoding.Default;
  if not SetConsoleCP(FInputEncoding.CodePage) then
    HandleSetConsoleEncodingError(GetLastError);
end;

procedure TWindowsConsole.SetConsoleOutputEncoding(const value : TEncoding);
begin
  if not TEncoding.IsStandardEncoding(FOutputEncoding) then
    FOutputEncoding.Free;
  if TEncoding.IsStandardEncoding(value) then
    FOutputEncoding := value
  else if value <> nil then
    FOutputEncoding := value.Clone
  else
    FOutputEncoding := TEncoding.Default;
  if not SetConsoleOutputCP(FOutputEncoding.CodePage) then
    HandleSetConsoleEncodingError(GetLastError);

end;

procedure TWindowsConsole.SetTempColors(foreground : TConsoleColor; background : TConsoleColor = TConsoleColor.NotSet);
begin
  FSavedTextAttributes := FCurrentTextAttributes;
  if background <> TConsoleColor.NotSet then
    SetColors(foreground, background)
  else
    SetForegroundColor(foreground);
end;

procedure TWindowsConsole.SetTitle(const value : string);
begin
  SetConsoleTitle(PChar(value));
end;

procedure TWindowsConsole.SetTreatControlCAsInput(value: boolean);
var
  mode : DWORD;
begin
 if FStdIn = INVALID_HANDLE_value then
    raise EInvalidOperation.Create('No console available');

  if (not GetConsoleMode(FStdIn, mode)) then
    RaiseLastOSError;

  if value then
    mode := mode and (not ENABLE_PROCESSED_INPUT)
  else
    mode := mode or ENABLE_PROCESSED_INPUT;

  if not SetConsoleMode(FStdIn, mode) then
    RaiseLastOSError;
end;

procedure TWindowsConsole.SetWindowPosition(Left, Top: integer);
var
  r : TRect;
begin
  r := GetConsoleBounds;
  r.Location := TPoint.Create(Left, Top);
  SetConsoleBounds(r);
end;

procedure TWindowsConsole.SetWindowSize(const width : integer; height : integer);
var
  bufferInfo : TConsoleScreenBufferInfo;
  srWindow : TSmallRect;
  coord : TCoord;
  resizeBuffer : boolean;
  lastError : Cardinal;
begin
  if IsHandleRedirected(FStdOut) then
    raise EInvalidOpException.Create('StdOut is redirected, cannot resize window');

  if width <= 0 then
    raise EArgumentOutOfRangeException.Create('Window Width must be a positive number');
  if height <= 0 then
    raise EArgumentOutOfRangeException.Create('Window Height must be a positive number');

  bufferInfo := GetBufferInfo;
  coord.x := bufferInfo.dwSize.x;
  coord.y := bufferInfo.dwSize.y;

  resizeBuffer := false;

  if (bufferInfo.dwSize.x < bufferInfo.srWindow.Left + width) then
  begin
    if (bufferInfo.srWindow.Left >= MaxShort - width) then
      raise EArgumentOutOfRangeException.Create('Window width must be less than : ' + IntToStr(MaxShort));
    coord.x := Short(bufferInfo.srWindow.Left + width);
    resizeBuffer := true;
  end;

  if (bufferInfo.dwSize.y < bufferInfo.srWindow.Top + height) then
  begin
    if (bufferInfo.srWindow.Top >= MaxShort - height) then
      raise EArgumentOutOfRangeException.Create('Window height must be les than ' + IntToStr(MaxShort));
    coord.y := Short(bufferInfo.srWindow.Top + height);
    resizeBuffer := true;
  end;

  if (resizeBuffer) then
  begin
    if not SetConsoleScreenBufferSize(FStdOut, coord) then
      RaiseLastOSError;
  end;

  srWindow := bufferInfo.srWindow;
  // Preserve the position, but change the size.
  srWindow.Bottom := Short(srWindow.Top + height - 1);
  srWindow.Right := Short(srWindow.Left + width - 1);

  if not SetConsoleWindowInfo(FStdOut, true, srWindow) then
  begin
    lastError := GetLastError; // preserve so we can raise it later.

    // If we resized the buffer, un-resize it.
    if resizeBuffer then
      SetConsoleScreenBufferSize(FStdOut, bufferInfo.dwSize);

    // Try to give a better error message here
    coord := GetLargestConsoleWindowSize(FStdOut);
    if (width > coord.x) then
      raise EArgumentOutOfRangeException.Create('Window width must be less than : ' + IntToStr(coord.x));
    if (height > coord.y) then
      raise EArgumentOutOfRangeException.Create('Window height must be less than : ' + IntToStr(coord.y));
    // it wasn't a size issue so something else is wrong
    RaiseLastOSError(lastError);
  end;

end;

function TWindowsConsole.TryGetBufferInfo(var info : TConsoleScreenBufferInfo) : boolean;
begin
  if FStdOut = INVALID_HANDLE_value then
    exit(false);
  Result := GetConsoleScreenBufferInfo(FStdOut, info);
end;

procedure TWindowsConsole.WriteString(const value : string);
var
  res : DWORD;
begin
  if FStdOut = INVALID_HANDLE_value then
    EnsureConsole; // last ditch effort;

  if FStdOut <> INVALID_HANDLE_value then
    WriteConsole(FStdOut, PChar(value), Length(value), res, nil);
end;

{ TWindowsConsoleStream }

constructor TWindowsConsoleStream.Create(handle : THandle; access : TFileAccess; useFileAPIs : boolean);
begin
  Assert(handle <> INVALID_HANDLE_value);
  inherited Create(handle, access);
  FUseFileAPIs := useFileAPIs;
end;

function TWindowsConsoleStream.Read(var Buffer; Count : Longint) : Longint;
var
  readSuccess : boolean;
  charsRead : DWORD;
  errorCode : DWORD;
  nNumberOfCharsToRead : DWORD;
begin
  if not FCanRead then
    raise EInvalidOperation.Create('Stream does not support reading');

  Result := 0;
  if Count = 0 then
    exit;

  if FUseFileAPIs then
    readSuccess := ReadFile(FHandle, Buffer, Count, DWORD(Result), nil)
  else
  begin
    // If the code page could be Unicode, we should use ReadConsole instead, e.g.
    nNumberOfCharsToRead := DWORD(Count) div BytesPerWChar;
    readSuccess := ReadConsole(FHandle, @Buffer, nNumberOfCharsToRead, charsRead, nil);
    Result := charsRead * BytesPerWChar;
  end;
  if readSuccess then
    exit;

  errorCode := GetLastError;
  // For pipes that are closing or broken, just stop.
  // (E.g. ERROR_NO_DATA ("pipe is being closed") is returned when we write to a console that is closing;
  // ERROR_BROKEN_PIPE ("pipe was closed") is returned when stdin was closed, which is not an error, but EOF.)
  if (errorCode = ERROR_NO_DATA) or (errorCode = ERROR_BROKEN_PIPE) then
    exit;
  RaiseLastOSError(errorCode);
end;

function TWindowsConsoleStream.Write(const Buffer; Count : Longint) : Longint;
var
  writeSuccess : boolean;
  numBytesWritten : DWORD;
  charsWritten : DWORD;
  errorCode : DWORD;
  charsToWrite : DWORD;
begin
  Result := 0;
  if not FCanWrite then
    raise EInvalidOperation.Create('Stream does not support writing');

  if Count = 0 then
    exit;

  if FUseFileAPIs then
  begin
    writeSuccess := WriteFile(FHandle, Buffer, Count, numBytesWritten, nil);
    Result := Longint(numBytesWritten);
    // In some cases we have seen numBytesWritten returned that is twice count;
    // so we aren't asserting the value of it. See https://github.com/dotnet/runtime/issues/23776
  end
  else
  begin
    // If the code page could be Unicode, we should use ReadConsole instead, e.g.
    // Note that WriteConsoleW has a max limit on num of chars to write (64K)
    // [https://learn.microsoft.com/windows/console/writeconsole]
    // However, we do not need to worry about that because the StreamWriter in Console has
    // a much shorter buffer size anyway.
    charsToWrite := DWORD(Count) div BytesPerWChar;
    writeSuccess := WriteConsole(FHandle, @Buffer, charsToWrite, charsWritten, nil);
    Result := charsWritten * BytesPerWChar;
  end;
  if writeSuccess then
    exit;

  errorCode := GetLastError;
  // For pipes that are closing or broken, just stop.
  // (E.g. ERROR_NO_DATA ("pipe is being closed") is returned when we write to a console that is closing;
  // ERROR_BROKEN_PIPE ("pipe was closed") is returned when stdin was closed, which is not an error, but EOF.)
  if (errorCode = ERROR_NO_DATA) or (errorCode = ERROR_BROKEN_PIPE) or (errorCode = ERROR_PIPE_NOT_CONNECTED) then
    exit;
  RaiseLastOSError(errorCode);

end;

end.
