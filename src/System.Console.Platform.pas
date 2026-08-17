unit System.Console.Platform;

interface

uses
  {$IF Defined(MSWINDOWS)}
  System.Console.Windows;
  {$ELSEIF Defined(MACOS) or Defined(LINUX)}
  System.Console.Posix;
  {$ELSE}
  {$MESSAGE FATAL 'VSoft.System.Console does not support this platform'}
  {$IFEND}


implementation

end.
