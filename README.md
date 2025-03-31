# VSoft.System.Console

A Delphi port of the dotnet System.Console class.

## Installation

### DPM

Install VSoft.System.Console in the DPM IDE plugin,  or 
```
dpm install VSoft.System.Console .\yourproject.dproj
```
### Manually
Clone the repository and add the System.Console.pas file to your project, or add the repo\src folder to your project's search path.

## Usage

The Console class is a static class, so you use it just like in C#



````delphi
uses
  System.Console;

begin
  Console.SetColors(TConsoleColor.Yellow, TConsoleColor.DarkBlue);
  Console.Clear;
  Console.SetCursorPosition(20,0);
  Console.WriteLine('abcdef');
  Console.ReadLine();
end;
````
 
