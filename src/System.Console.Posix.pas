unit System.Console.Posix;

interface

uses
  System.Console.Types,
  System.Console.InternalTypes;

type
  TPosixConsole = class(TConsoleImplementation)
  protected

  public
    constructor Create;
    destructor Destroy;override;
  end;

implementation

{ TLinuxConsole }

constructor TPosixConsole.Create;
begin

end;

destructor TPosixConsole.Destroy;
begin

  inherited;
end;

end.
