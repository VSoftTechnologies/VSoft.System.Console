unit System.Console.ConsoleStream;

interface

uses
  System.Classes,
  System.Console.InternalTypes;

type
  //Do not use directly, create descendents
  TConsoleStream = class(THandleStream)
  protected
    FCanRead  : boolean;
    FCanWrite : boolean;
  protected
    procedure SetSize(NewSize: Longint); override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(handle : THandle; fileAccess : TFileAccess);
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

implementation

uses
  System.SysUtils;


{ TConsoleStream }

constructor TConsoleStream.Create(handle: THandle; fileAccess: TFileAccess);
begin
  inherited Create(handle);
  FCanRead := fileAccess = TFileAccess.Read;
  FCanWrite := fileAccess = TFileAccess.Write;
end;

function TConsoleStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  raise ENotSupportedException.Create('Seek not supported on consol stream');
end;

procedure TConsoleStream.SetSize(const NewSize: Int64);
begin
  raise ENotSupportedException.Create('SetSize not supported on console stream');
end;

procedure TConsoleStream.SetSize(NewSize: Longint);
begin
  raise ENotSupportedException.Create('SetSize not supported on console stream');
end;


end.
