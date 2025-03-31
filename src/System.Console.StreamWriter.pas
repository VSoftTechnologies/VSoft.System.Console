unit System.Console.StreamWriter;

interface

uses
  System.SysUtils,
  System.Classes;

  //Cannot use TStreamWriter as it always writes the preamble.

type
  TConsoleStreamWriter = class(TTextWriter)
  private
    FStream: TStream;
    FEncoding: TEncoding;
    FNewLine: string;
    FAutoFlush: boolean;
  protected
    FBufferIndex: Integer;
    FBuffer: TBytes;
    procedure WriteBytes(Bytes: TBytes);
  public
    constructor Create(Stream: TStream; Encoding: TEncoding); overload;
    destructor Destroy; override;
    procedure Close; override;
    procedure Flush; override;
    procedure Write(value: boolean); override;
    procedure Write(value: Char); override;
    procedure Write(const value: TCharArray); override;
    procedure Write(value: Double); override;
    procedure Write(value: Integer); override;
    procedure Write(value: Int64); override;
    procedure Write(value: TObject); override;
    procedure Write(value: Single); override;
    procedure Write(const value: string); override;
    procedure Write(value: Cardinal); override;
    procedure Write(value: UInt64); override;
    procedure Write(const format: string; args: array of const); override;
    procedure Write(const value: TCharArray; index : integer; count: Integer); override;
    procedure WriteLine; override;
    procedure WriteLine(value: boolean); override;
    procedure WriteLine(value: Char); override;
    procedure WriteLine(const value: TCharArray); override;
    procedure WriteLine(value: Double); override;
    procedure WriteLine(value: Integer); override;
    procedure WriteLine(value: Int64); override;
    procedure WriteLine(value: TObject); override;
    procedure WriteLine(value: Single); override;
    procedure WriteLine(const value: string); override;
    procedure WriteLine(value: Cardinal); override;
    procedure WriteLine(value: UInt64); override;
    procedure WriteLine(const Format: string; Args: array of const); override;
    procedure WriteLine(const value: TCharArray; Index, Count: Integer); override;
    property AutoFlush: boolean read FAutoFlush write FAutoFlush;
    property NewLine: string read FNewLine write FNewLine;
    property Encoding: TEncoding read FEncoding;
    property BaseStream: TStream read FStream;
  end;

implementation

{ TConsoleStreamWriter }

procedure TConsoleStreamWriter.Close;
begin
  Flush;
  FreeAndNil(FStream);
end;


constructor TConsoleStreamWriter.Create(Stream: TStream; Encoding: TEncoding);
begin
  inherited Create;
  FStream := Stream;
  FEncoding := Encoding;

  //no point in a large buffer for console output;
  SetLength(FBuffer, 256);
  FBufferIndex := 0;
  FNewLine := sLineBreak;
  FAutoFlush := True;

end;

destructor TConsoleStreamWriter.Destroy;
begin
  Close;
  SetLength(FBuffer, 0);
  inherited;
end;

procedure TConsoleStreamWriter.Flush;
begin
  if FBufferIndex = 0 then
    Exit;
  if FStream = nil then
    Exit;

  try
    FStream.WriteBuffer(FBuffer, FBufferIndex);
  finally
    FBufferIndex := 0;
  end;
end;


procedure TConsoleStreamWriter.Write(value: Cardinal);
begin
  WriteBytes(FEncoding.GetBytes(UIntToStr(value)));
end;

procedure TConsoleStreamWriter.Write(const value: string);
begin
  WriteBytes(FEncoding.GetBytes(value));
end;

procedure TConsoleStreamWriter.Write(value: Single);
begin
  WriteBytes(FEncoding.GetBytes(FloatToStr(value)));
end;

procedure TConsoleStreamWriter.Write(const value: TCharArray; index : integer; count: Integer);
var
  Bytes: TBytes;
begin
  SetLength(Bytes, Count * 4);
  SetLength(Bytes, FEncoding.GetBytes(value, Index, Count, Bytes, 0));
  WriteBytes(Bytes);
end;

procedure TConsoleStreamWriter.Write(const format: string; args: array of const);
begin
  WriteBytes(FEncoding.GetBytes(System.SysUtils.Format(Format, args)));
end;

procedure TConsoleStreamWriter.Write(value: UInt64);
begin
  WriteBytes(FEncoding.GetBytes(UIntToStr(value)));
end;

procedure TConsoleStreamWriter.Write(value: boolean);
begin
  WriteBytes(FEncoding.GetBytes(BoolToStr(value, True)));
end;

procedure TConsoleStreamWriter.Write(value: Integer);
begin
  WriteBytes(FEncoding.GetBytes(IntToStr(value)));
end;

procedure TConsoleStreamWriter.Write(value: Int64);
begin
  WriteBytes(FEncoding.GetBytes(IntToStr(value)));
end;

procedure TConsoleStreamWriter.Write(value: TObject);
begin
  WriteBytes(FEncoding.GetBytes(value.ToString));
end;

procedure TConsoleStreamWriter.Write(value: Char);
begin
  WriteBytes(FEncoding.GetBytes(value));
end;

procedure TConsoleStreamWriter.Write(const value: TCharArray);
begin
  WriteBytes(FEncoding.GetBytes(value));
end;

procedure TConsoleStreamWriter.Write(value: Double);
begin
  WriteBytes(FEncoding.GetBytes(FloatToStr(value)));
end;

procedure TConsoleStreamWriter.WriteBytes(Bytes: TBytes);
var
  ByteIndex: Integer;
  WriteLen: Integer;
begin
  ByteIndex := 0;

  while ByteIndex < Length(Bytes) do
  begin
    WriteLen := Length(Bytes) - ByteIndex;
    if WriteLen > Length(FBuffer) - FBufferIndex then
      WriteLen := Length(FBuffer) - FBufferIndex;

    Move(Bytes[ByteIndex], FBuffer[FBufferIndex], WriteLen);

    Inc(FBufferIndex, WriteLen);
    Inc(ByteIndex, WriteLen);

    if FBufferIndex >= Length(FBuffer) then
      Flush;
  end;

  if FAutoFlush then
    Flush;
end;

procedure TConsoleStreamWriter.WriteLine(const value: TCharArray);
begin
  WriteBytes(FEncoding.GetBytes(value));
  WriteBytes(FEncoding.GetBytes(FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: Double);
begin
  WriteBytes(FEncoding.GetBytes(FloatToStr(value) + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: Integer);
begin
  WriteBytes(FEncoding.GetBytes(IntToStr(value) + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine;
begin
  WriteBytes(FEncoding.GetBytes(FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: boolean);
begin
  WriteBytes(FEncoding.GetBytes(BoolToStr(value, True) + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: Char);
begin
  WriteBytes(FEncoding.GetBytes(value));
  WriteBytes(FEncoding.GetBytes(FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: Cardinal);
begin
  WriteBytes(FEncoding.GetBytes(UIntToStr(value) + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: UInt64);
begin
  WriteBytes(FEncoding.GetBytes(UIntToStr(value) + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(const Format: string; Args: array of const);
begin
  WriteBytes(FEncoding.GetBytes(System.SysUtils.Format(Format, Args) + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(const value: TCharArray; Index, Count: Integer);
var
  Bytes: TBytes;
begin
  SetLength(Bytes, Count * 4);
  SetLength(Bytes, FEncoding.GetBytes(value, Index, Count, Bytes, 0));
  WriteBytes(Bytes);
  WriteBytes(FEncoding.GetBytes(FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: Int64);
begin
  WriteBytes(FEncoding.GetBytes(IntToStr(value) + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: TObject);
begin
  WriteBytes(FEncoding.GetBytes(value.ToString + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(value: Single);
begin
  WriteBytes(FEncoding.GetBytes(FloatToStr(value) + FNewLine));
end;

procedure TConsoleStreamWriter.WriteLine(const value: string);
begin
  WriteBytes(FEncoding.GetBytes(value + FNewLine));
end;

end.
