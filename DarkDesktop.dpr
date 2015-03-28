{
Third parties' files :
GDIPAPI.PAS
DirectDraw.pas
DirectX.inc
Jedi.inc
GDIPObj.pas
}
program DarkDesktop;

uses
///  FastMM4,
  Forms,
  Windows,
  Messages,
  DarkDesktop_src in 'DarkDesktop_src.pas' {frmDarkDesktop},
  Settings in 'Settings.pas' {frmSettings},
  Splash in 'Splash.pas' {FormSplash};

{$R *.res}
const
  CM_RESTORE = WM_USER + $1000;
var
  RvHandle : HWND;
begin
//evitamos doble instancia
  RvHandle:=FindWindow('DarkDesktopClass',NIL);
  if RvHandle > 0 then
  begin
    PostMessage(RvHandle,CM_RESTORE, 0,0);
    exit;
  end;

  Application.Initialize;
  Application.Title := 'DarkDesktop';
  Application.ShowMainForm :=false;
  Application.CreateForm(TfrmDarkDesktop, frmDarkDesktop);
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.CreateForm(TFormSplash, FormSplash);
  Application.Run;

end.
