unit System.Console.Types;

interface

uses
  System.SysUtils,
  System.Classes;

{$SCOPEDENUMS ON}

type
  TConsoleKey = (
      None = $0,
      Backspace = $8,
      Tab = $9,
      Clear = $C,
      Enter = $D,
      Pause = $13,
      Escape = $1B,
      Spacebar = $20,
      PageUp = $21,
      PageDown = $22,
      &End = $23,
      Home = $24,
      LeftArrow = $25,
      UpArrow = $26,
      RightArrow = $27,
      DownArrow = $28,
      Select = $29,
      Print = $2A,
      Execute = $2B,
      PrintScreen = $2C,
      Insert = $2D,
      Delete = $2E,
      Help = $2F,
      D0 = $30,  // 0 through 9
      D1 = $31,
      D2 = $32,
      D3 = $33,
      D4 = $34,
      D5 = $35,
      D6 = $36,
      D7 = $37,
      D8 = $38,
      D9 = $39,
      A = $41,
      B = $42,
      C = $43,
      D = $44,
      E = $45,
      F = $46,
      G = $47,
      H = $48,
      I = $49,
      J = $4A,
      K = $4B,
      L = $4C,
      M = $4D,
      N = $4E,
      O = $4F,
      P = $50,
      Q = $51,
      R = $52,
      S = $53,
      T = $54,
      U = $55,
      V = $56,
      W = $57,
      X = $58,
      Y = $59,
      Z = $5A,
      LeftWindows = $5B,  // Microsoft Natural keyboard
      RightWindows = $5C,  // Microsoft Natural keyboard
      Applications = $5D,  // Microsoft Natural keyboard
      Sleep = $5F,
      NumPad0 = $60,
      NumPad1 = $61,
      NumPad2 = $62,
      NumPad3 = $63,
      NumPad4 = $64,
      NumPad5 = $65,
      NumPad6 = $66,
      NumPad7 = $67,
      NumPad8 = $68,
      NumPad9 = $69,
      Multiply = $6A,
      Add = $6B,
      Separator = $6C,
      Subtract = $6D,
      Decimal = $6E,
      Divide = $6F,
      F1 = $70,
      F2 = $71,
      F3 = $72,
      F4 = $73,
      F5 = $74,
      F6 = $75,
      F7 = $76,
      F8 = $77,
      F9 = $78,
      F10 = $79,
      F11 = $7A,
      F12 = $7B,
      F13 = $7C,
      F14 = $7D,
      F15 = $7E,
      F16 = $7F,
      F17 = $80,
      F18 = $81,
      F19 = $82,
      F20 = $83,
      F21 = $84,
      F22 = $85,
      F23 = $86,
      F24 = $87,
      BrowserBack = $A6,  // Windows 2000/XP
      BrowserForward = $A7,  // Windows 2000/XP
      BrowserRefresh = $A8,  // Windows 2000/XP
      BrowserStop = $A9,  // Windows 2000/XP
      BrowserSearch = $AA,  // Windows 2000/XP
      BrowserFavorites = $AB,  // Windows 2000/XP
      BrowserHome = $AC,  // Windows 2000/XP
      VolumeMute = $AD,  // Windows 2000/XP
      VolumeDown = $AE,  // Windows 2000/XP
      VolumeUp = $AF,  // Windows 2000/XP
      MediaNext = $B0,  // Windows 2000/XP
      MediaPrevious = $B1,  // Windows 2000/XP
      MediaStop = $B2,  // Windows 2000/XP
      MediaPlay = $B3,  // Windows 2000/XP
      LaunchMail = $B4,  // Windows 2000/XP
      LaunchMediaSelect = $B5,  // Windows 2000/XP
      LaunchApp1 = $B6,  // Windows 2000/XP
      LaunchApp2 = $B7,  // Windows 2000/XP
      Oem1 = $BA,
      OemPlus = $BB,
      OemComma = $BC,
      OemMinus = $BD,
      OemPeriod = $BE,
      Oem2 = $BF,
      Oem3 = $C0,
      Oem4 = $DB,
      Oem5 = $DC,
      Oem6 = $DD,
      Oem7 = $DE,
      Oem8 = $DF,
      Oem102 = $E2,  // Win2K/XP: Either angle or backslash on RT 102-key keyboard
      Process = $E5,  // Windows: IME Process Key
      Packet = $E7,  // Win2K/XP: Used to pass Unicode chars as if keystrokes
      Attention = $F6,
      CrSel = $F7,
      ExSel = $F8,
      EraseEndOfFile = $F9,
      Play = $FA,
      Zoom = $FB,
      NoName = $FC,  // Reserved
      Pa1 = $FD,
      OemClear = $FE
  );

  TConsoleColor = (
        Black = 0,
        DarkBlue = 1,
        DarkGreen = 2,
        DarkCyan = 3,
        DarkRed = 4,
        DarkMagenta = 5,
        DarkYellow = 6,
        Gray = 7,
        DarkGray = 8,
        Blue = 9,
        Green = 10,
        Cyan = 11,
        Red = 12,
        Magenta = 13,
        Yellow = 14,
        White = 15,
        NotSet = 99
    );

    TConsoleModifier = (
        None = 0,
        Alt = 1,
        Shift = 2,
        Control = 4
    );

    TConsoleModifiers = set of TConsoleModifier;

    TConsoleSpecialKey = (
        ControlC = 0,
        ControlBreak = 1,
        ControlClose = 2,
        ControlLogOff = 3,
        ControlShutdown = 4
    );

  EUnsupportedException = class(Exception);

  TConsoleKeyInfo = record
  strict private
    FKey     : TConsoleKey;
    FKeyChar : Char;
    FMods    : TConsoleModifiers;
  public
    constructor Create(keyChar : Char; key : TConsoleKey; shift, alt, control : boolean);
    property Key : TConsoleKey read FKey write FKey;
    property KeyChar : Char read FKeyChar write FKeyChar;
    property Modifiers : TConsoleModifiers read FMods;
  end;


  TConsoleCancelEventArgs = class
  private
    FCancel : boolean;
    FSpecialKey : TConsoleSpecialKey;
  public
    constructor Create(key : TConsoleSpecialKey);
    property Cancel : boolean read FCancel write FCancel;
    property SpecialKey : TConsoleSpecialKey read FSpecialKey;
  end;

  TConsoleCancelEventHandler = procedure(const Sender : TObject; const args : TConsoleCancelEventArgs);

implementation


{ TConsoleKeyInfo }

constructor TConsoleKeyInfo.Create(keyChar: Char; key: TConsoleKey; shift, alt, control: boolean);
begin
  FKeyChar := keyChar;
  FKey := key;
  FMods := [];
  if shift then
    Include(FMods, TConsoleModifier.Shift);
  if alt then
    Include(FMods, TConsoleModifier.Alt);
  if control then
    Include(FMods, TConsoleModifier.Control);
end;

{ TConsoleCancelEventArgs }

constructor TConsoleCancelEventArgs.Create(key: TConsoleSpecialKey);
begin
  FSpecialKey := key;
end;

end.
