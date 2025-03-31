unit System.Console.SyncTextReader;

interface

{$I 'System.Console.inc'}

uses
  System.SysUtils,
  System.Classes;

type
  TSyncTextReader = class(TTextReader)
  private
    FReader : TTextReader;
  public
    procedure Close; override;
    function Peek: Integer; override;
    function Read: Integer; overload; override;

    {$IFDEF VARBUFFER}
    function Read(var Buffer: TCharArray; Index, Count: Integer): Integer; overload; override;
    {$ELSE}
    function Read(const Buffer: TCharArray; Index, Count: Integer): Integer; overload; override;
    {$ENDIF}

    {$IFDEF VARBUFFER}
    function ReadBlock(var Buffer: TCharArray; Index, Count: Integer): Integer; override;
    {$ELSE}
    function ReadBlock(const Buffer: TCharArray; Index, Count: Integer): Integer; override;
    {$ENDIF}

    function ReadLine: string; override;
    function ReadToEnd: string; override;
    {$IFDEF 10_3UP}
    procedure Rewind; override;
    {$ENDIF}
    {$IFDEF 12_UP}
    function GetEndOfStream: boolean; override;
    {$ENDIF}
    constructor Create(const reader : TTextReader);
    class function GetSynchronizedTextReader(const reader : TTextReader) : TSyncTextReader;

  end;

implementation

{ TSyncTextReader }

procedure TSyncTextReader.Close;
begin
  MonitorEnter(Self);
  try
    FReader.Close;
  finally
    MonitorExit(self);
  end;

end;

constructor TSyncTextReader.Create(const reader: TTextReader);
begin
  FReader := reader;
end;

{$IFDEF 12_UP}
function TSyncTextReader.GetEndOfStream: boolean;
begin
  MonitorEnter(Self);
  try
    result := FReader.EndOfStream;
  finally
    MonitorExit(self);
  end;

end;
{$ENDIF}

class function TSyncTextReader.GetSynchronizedTextReader(const reader: TTextReader): TSyncTextReader;
begin
  if reader is TSyncTextReader then
    result := reader as TSyncTextReader
  else
    result := TSyncTextReader.Create(reader);
end;

function TSyncTextReader.Peek: Integer;
begin
  MonitorEnter(Self);
  try
    result := FReader.Peek;
  finally
    MonitorExit(self);
  end;
end;

{$IFDEF VARBUFFER}
function TSyncTextReader.Read(var Buffer: TCharArray; Index, Count: Integer): Integer;
{$ELSE}
function TSyncTextReader.Read(const Buffer: TCharArray; Index, Count: Integer): Integer;
{$ENDIF}
begin
  MonitorEnter(Self);
  try
    result := FReader.Read(Buffer, Index, Count);
  finally
    MonitorExit(self);
  end;
end;

function TSyncTextReader.Read: Integer;
begin
  MonitorEnter(Self);
  try
    result := FReader.Read;
  finally
    MonitorExit(self);
  end;
end;

{$IFDEF VARBUFFER}
function TSyncTextReader.ReadBlock(var Buffer: TCharArray; Index, Count: Integer): Integer;
{$ELSE}
function TSyncTextReader.ReadBlock(const Buffer: TCharArray; Index, Count: Integer): Integer;
{$ENDIF}
begin
  MonitorEnter(Self);
  try
    result := FReader.ReadBlock(Buffer, Index, Count);
  finally
    MonitorExit(self);
  end;
end;

function TSyncTextReader.ReadLine: string;
begin
  MonitorEnter(Self);
  try
    result := FReader.ReadLine;
  finally
    MonitorExit(self);
  end;
end;

function TSyncTextReader.ReadToEnd: string;
begin
  MonitorEnter(Self);
  try
    result := FReader.ReadToEnd;
  finally
    MonitorExit(self);
  end;
end;

{$IFDEF 10_3UP}
procedure TSyncTextReader.Rewind;
begin
  MonitorEnter(Self);
  try
    FReader.Rewind;
  finally
    MonitorExit(self);
  end;
end;
{$ENDIF}

end.
