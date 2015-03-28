{
DarkDesktop_src.pas
  Author: vhanla (Victor Alberto Gil)
  DarkDesktop - software to adjust screen brightness
  
  License: GNU GENERAL PUBLIC LICENSE Version 2, see LICENSE file

  CHANGELOG:
  2014-03-12:
    Exclude it from AeroPeek
    it needs to be digitally signed in order to make it work using the manifest file in conjuction with uiaccess=true
    in order to be available over any metro/modernui application, including the startmenu/screen
    Using dwmapi to exclude from aero peek and flip3d on windows 7 (this one not tested)

  2014-12-13:
    Modified Settings.frm
      chkCrHalo : to enable or disable cursor's halo
    Fixed Global Shortcut [ctrl-alt-x : toggle; ctrl-alt-z : set opacity with mouse cursor]

  2014-12-07:
    Trying out a new method, creating a translucent bitmap and WS_EXLAYERED windows
    var bmpmask: TBitmap32; uses gr32;
  2014-12-06
    Changed icons, added imagelist with the trayicons for ON and OFF states
    added variable IconoTray: TIcon;

    Added WNProc to restore Icon tray after Explorer restart

    Added SetPriorityClass to formcreate in order to make it less cpu intensive

    Added Updateposition from AMPortable, in order to show the settings window right above/below the icon tray

    Added SwitchToThisWindow Windows API in order to focus to the settings window thus it can be hidden if focus is lost

    Added UpdateClockPosition in order to make it easy to update its position

    Added Block me feature, this will be configured in order to let people block themselves to relax

    Adding Pomodoro features

    Adding picture to show relax time

    Added Shape (circle) and tmrMouse set to 3 in interval, it seems it doesn't hog the CPU :)
    Added doublebuffered on formcreate

    Added Screen resolution change message handling

    Added ScreenWorkAreaWidth changes monitor in new timer, tmrWorkAreaMonitor
    variable used ActualWorkAreaWidth : Integer;

  2014-08-14 -
    Fixed bad hotkeys
}
unit DarkDesktop_src;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ShellApi, Menus, IniFiles, jpeg, ExtCtrls, XPMan, Registry,
  StdCtrls, Vcl.ImgList, GR32_Image, GR32, DWMApi;

type
  TfrmDarkDesktop = class(TForm)
    PopupMenu1: TPopupMenu;
    Configuracin1: TMenuItem;
    Acercade1: TMenuItem;
    N1: TMenuItem;
    Salir1: TMenuItem;
    IniciarjuntoconWindows1: TMenuItem;
    Timer1: TTimer;
    lblOpacityChange: TLabel;
    Timer2: TTimer;
    Desactivar1: TMenuItem;
    ImageList1: TImageList;
    lblClock: TLabel;
    tmrClock: TTimer;
    Image321: TImage32;
    Shape1: TShape;
    tmrCrHalo: TTimer;
    tmrWorkAreaMonitor: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Salir1Click(Sender: TObject);
    procedure Acercade1Click(Sender: TObject);
    procedure Configuracin1Click(Sender: TObject);
    procedure IniciarjuntoconWindows1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Desactivar1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrClockTimer(Sender: TObject);
    procedure UpdateClockPosition;
    procedure FormResize(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tmrCrHaloTimer(Sender: TObject);
    procedure tmrWorkAreaMonitorTimer(Sender: TObject);
  private
    { Private declarations }
    IconData : TNotifyIconData;
    procedure Iconito(var msg: TMessage); message WM_USER+1;
    procedure WMShowWindow(var msg: TWMShowWindow);
    procedure WMHotKey(var msg: TWMHotKey); message WM_HOTKEY;
    procedure WndProc(var msg: TMessage); override;
    procedure WMDisplayChange(var Message: TWMDisplayChange);message WM_DISPLAYCHANGE;
  public
    { Public declarations }
    procedure CreateParams(var params: TCreateParams); override;
    procedure RestoreRequest(var message: TMessage); message WM_USER + $1000;
  end;

var
  frmDarkDesktop: TfrmDarkDesktop;
  fwm_TaskbarRestart : Cardinal;
  Opacity: Integer;
  OpInterval: Integer; 
  OpPersistent : Boolean;
  OpPersistentInterval: Integer;
  OpShowOSD : Boolean;
  currentMouseX : integer;
  IconoTray : TIcon;
  ActualWorkAreaWidth : Integer;
  BmpMask: TBitmap32;

  procedure SwitchToThisWindow(h1: hWnd; x: bool); stdcall;
  external user32 Name 'SwitchToThisWindow';

{type DWMWINDOWATTRIBUTE = (
  DWMWA_NCRENDERING_ENABLE = 1,
  DWMWA_NCRENDERING_POLICY,
  DWMWA_TRANSITIONS_FORCEDISABLED,
  DWMWA_ALLOW_NCPAINT,
  DWMWA_CAPTION_BUTTON_BOUNDS,
  DWMWA_NONCLIENT_RTL_LAYOUT,
  DWMWA_FORCE_ICONIC_REPRESENTATION,
  DWMWA_FLIP3D_POLICY,
  DWMWA_EXTENDED_FRAME_BOUNDS,
  DWMWA_HAS_ICONIC_BITMAP,
  DWMWA_DISALLOW_PEEK,
  DWMWA_EXCLUDED_FROM_PEEK,
  DWMWA_LAST
);

  function DwmSetWindowAttribute(hwnd:HWND; dwAttribute: DWORD; pvAttribute: Pointer; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll' name 'DwmSetWindowAttribute';
}
implementation

uses Settings, Splash, Math;

{$R *.dfm}
procedure AutoStartState;
var key: string;
     Reg: TRegIniFile;
begin
  key := '\Software\Microsoft\Windows\CurrentVersion\Run';
  Reg:=TRegIniFile.Create;
try
  Reg.RootKey:=HKEY_CURRENT_USER;
  if reg.ReadString(key,'DarkDesktop','')<>'' then
  frmDarkDesktop.IniciarjuntoconWindows1.Checked:=true;
  finally
  Reg.Free;
  end;
end;

procedure TfrmDarkDesktop.WMHotKey(var msg: TWMHotKey);
var
ini: TIniFile;
//i:integer;
actualOpacity: integer;
begin
  actualOpacity:=Opacity;

  if Msg.HotKey = GlobalFindAtom('ALT_LESS')then
    if Opacity+OpInterval<=255 then  Opacity:=Opacity+OpInterval;
  if Msg.HotKey = GlobalFindAtom('ALT_PLUS')then
    if Opacity>=OpInterval then Opacity:=Opacity-OpInterval;

  if msg.HotKey = GlobalFindAtom('CTRL_WIN_ALT')then
  begin
    
  if (currentMouseX <> mouse.CursorPos.X) and(Desactivar1.Caption<>'&Activar') then
  begin
    currentMouseX := Mouse.CursorPos.X;
    opacity:= trunc(Mouse.CursorPos.X / Screen.Width*255);
  end;

  end;

  if msg.HotKey = GlobalFindAtom('DISABLEWIN')then
  begin
    if Timer1.Enabled then begin
      frmDarkDesktop.Hide;
      Desactivar1.Caption:='&Activar';
      Timer1.Enabled:=false;
      ImageList1.GetIcon(0, IconoTray);
      IconData.hIcon := IconoTray.Handle;
      Shell_NotifyIcon(NIM_MODIFY,@IconData);
    end
    else begin
      frmDarkDesktop.Show;
      Desactivar1.Caption:='&Desactivar';
      Timer1.Enabled:=true;
      ImageList1.GetIcon(1, IconoTray);
      IconData.hIcon := IconoTray.Handle;
      Shell_NotifyIcon(NIM_MODIFY,@IconData);
    end;
  end;

  if actualOpacity <> Opacity then
  begin
    SetLayeredWindowAttributes(frmDarkDesktop.Handle,0,Opacity, LWA_ALPHA);

    if frmSettings.Showing then frmSettings.TrackBar1.Position:=Opacity;

    ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'config.ini');
    try
      ini.WriteInteger('Settings','Opacity',Opacity);
    finally
      ini.Free;
    end;

    //Show OSD text
    if OpShowOSD then
    begin
      //lblOpacityChange.Caption:='Opacidad: '+inttostr(Opacity);
      lblOpacityChange.Caption:='';
      lblOpacityChange.Top:=Screen.Height div 2;
      lblOpacityChange.Width:=Screen.Width;
      //  lblOpacityChange.Font.Size:=6;
      //  lblOpacityChange.Font.Color:=clWhite;
      //anima pero consume recursos
      {for i:=0 to Opacity div 4 do
      begin
        if (Opacity div 4)div 2 = i - 1 then lblOpacityChange.Caption:=lblOpacityChange.Caption+'[ '+IntToStr(trunc(Opacity/255*100))+' ]';
        lblOpacityChange.Caption:=lblOpacityChange.Caption+'|';
      end;
      }
      lblOpacityChange.Caption:=IntToStr(Opacity)+'/255';
      lblOpacityChange.Align:=alBottom;
      lblOpacityChange.Visible:=true;
      timer2.Enabled:=false;
      sleep(10);
      timer2.Enabled:=true;
    end;
  end;
end;

procedure TfrmDarkDesktop.Iconito(var msg: TMessage);
var
p: TPoint;
begin
  if msg.LParam = WM_RBUTTONDOWN THen begin
  try //posible error code 5 , access denied
    GetCursorPos(p);
    frmDarkDesktop.PopupMenu1.Popup(p.X,p.Y );
  except
  end;
    PostMessage(handle,WM_NULL,0,0)
  end
//  else if (msg.LParam = WM_LBUTTONDBLCLK)  and (frmSettings.Showing = false )then
  else if (msg.LParam = WM_LBUTTONUP)  and (frmSettings.Showing = false )then
  begin
   frmSettings.Show;//Modal
    SwitchToThisWindow(frmSettings.Handle,True);
    frmSettings.UpdatePosition;
  end;
{  else if msg.LParam = WM_LBUTTONUP then
  begin
    if Timer1.Enabled then begin
      frmDarkDesktop.Hide;
      Desactivar1.Caption:='&Activar';
      Timer1.Enabled:=false;
    end
    else begin
      frmDarkDesktop.Show;
      Desactivar1.Caption:='&Desactivar';
      Timer1.Enabled:=true;
    end;
  end;}
end;
//the following will deny minimization
procedure TfrmDarkDesktop.WMShowWindow(var msg: TWMShowWindow);
begin
  if not msg.Show then
  msg.Result := 0
  else
    inherited
end;

procedure TfrmDarkDesktop.WndProc(var msg: TMessage);
begin
  if msg.Msg = fwm_TaskbarRestart then
  begin
    Shell_NotifyIcon(NIM_ADD, @icondata);
  end;
  inherited WndProc(msg);
end;

procedure TfrmDarkDesktop.UpdateClockPosition;
begin
    with frmSettings do
  begin
    if rbClock1.Checked then
    begin
      lblClock.Left := 100;
      lblClock.Top  := 100;
    end
    else if rbClock2.Checked then
    begin
      lblClock.Left := (self.Width - lblClock.Width) div 2;
      lblClock.Top  := 100;
    end
    else if rbClock3.Checked then
    begin
      lblClock.Left := self.Width - lblClock.Width - 100;
      lblClock.Top  := 100;
    end
    else if rbClock4.Checked then
    begin
      lblClock.Left := 100;
      lblClock.Top  := (self.Height - lblClock.Height) div 2;
    end
    else if rbClock5.Checked then
    begin
      lblClock.Left := (self.Width - lblClock.Width) div 2;
      lblClock.Top  := (self.Height - lblClock.Height) div 2;
    end
    else if rbClock6.Checked then
    begin
      lblClock.Left := self.Width - lblClock.Width - 100;
      lblClock.Top  := (self.Height - lblClock.Height) div 2;
    end
    else if rbClock7.Checked then
    begin
      lblClock.Left := 100;
      lblClock.Top  := self.Height - lblClock.Height - 100;
    end
    else if rbClock8.Checked then
    begin
      lblClock.Left := (self.Width - lblClock.Width) div 2;
      lblClock.Top  := self.Height - lblClock.Height - 100;
    end
    else if rbClock9.Checked then
    begin
      lblClock.Left := self.Width - lblClock.Width - 100;
      lblClock.Top  := self.Height - lblClock.Height - 100;
    end;
  end;
end;

procedure TfrmDarkDesktop.WMDisplayChange(var Message: TWMDisplayChange);
begin
//  Width := Message.Width;
//  Height := Message.Height;

  if Message.Height < 768 then //it might be showing a windows 8 app, so lets bypass it in less resolutions
  Width := Message.Width
  else
  Width := Screen.WorkAreaWidth;
  Height := Message.Height;
end;

procedure TfrmDarkDesktop.CreateParams(var params: TCreateParams);
begin
  inherited CreateParams(Params);
  params.WinClassName := 'DarkDesktopClass';
  //esto es para que no robe el foco pero no es usable aquí
//  params.ExStyle:= params.ExStyle or WS_EX_NOACTIVATE or WS_EX_TOOLWINDOW;
end;

procedure TfrmDarkDesktop.RestoreRequest(var message: TMessage);
begin
//mostramos si está oculto
  frmDarkDesktop.Show;
end;

procedure TfrmDarkDesktop.FormCreate(Sender: TObject);
var
ini: TIniFile;
  I: Integer;
//opacity: Integer;
//rc : TRect;

  BlendFunc : TBlendFunction;
  BmpPos : TPoint;
  BmpSize : TSize;

  //exclude from aeropeek
  renderPolicy: integer;//DWMWINDOWATTRIBUTE;
begin
  SetPriorityClass(GetCurrentProcess, $4000);
  //exclude from aeropeek
  if DwmCompositionEnabled then
    DwmSetWindowAttribute(Handle, DWMWA_EXCLUDED_FROM_PEEK or DWMWA_FLIP3D_POLICY, @renderPolicy, SizeOf(Integer));


  //showmessage(inttostr(screen.monitorcount));
  //BoundsRect:=screen.Monitors[1].BoundsRect+screen.Monitors[0].BoundsRect;
  if (GetSystemMetrics(SM_CMONITORS)>1)then
  begin
//    showmessage('This app only supports one monitor!');

  end;
  //hiding from taskbar
{  ShowWindow(Application.Handle, SW_HIDE) ;
  SetWindowLong(Application.Handle, GWL_EXSTYLE, getWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW) ;
  ShowWindow(Application.Handle, SW_SHOW) ;}


  BmpMask := TBitmap32.Create;

  frmDarkDesktop.Color:= clblack;
  frmDarkDesktop.AlphaBlend:=true;
  frmDarkDesktop.AlphaBlendValue:=128;
  frmDarkDesktop.BorderStyle:=bsNone;
//  frmDarkDesktop.WindowState:=wsMaximized;

//primero detectamos si es mas de un monitor
if Screen.MonitorCount>1 then
begin
  //copiamos las coordenadas del primer monitor
  frmDarkDesktop.Left:=Screen.Monitors[0].Left;
  frmDarkDesktop.Top:=Screen.Monitors[0].Top;
  frmDarkDesktop.Width:=0;//Screen.Monitors[0].Width;
  frmDarkDesktop.Height:=110;//Screen.Monitors[0].Height;

  //ahora con los siguientes
  for I := 1 to Screen.MonitorCount-1 do
  begin
    if frmDarkDesktop.Left>Screen.Monitors[I].Left then
      frmDarkDesktop.Left:=Screen.Monitors[I].Left;
    if frmDarkDesktop.Top>Screen.Monitors[I].Top then
      frmDarkDesktop.Top:=Screen.Monitors[I].Top;
  end;
  //una vez encontrado left y top buscamos el ancho y alto
  for I := 0 to Screen.MonitorCount-1 do
  begin
//    ShowMessage(IntToStr(frmDarkDesktop.Left+Screen.Monitors[I].Width));
    if frmDarkDesktop.Left+frmDarkDesktop.Width<Screen.Monitors[I].Left+Screen.Monitors[I].Width then
    frmDarkDesktop.Width:=Screen.Monitors[I].Left+Screen.Monitors[I].Width-frmDarkDesktop.Left;

    if frmDarkDesktop.Top+frmDarkDesktop.Height<Screen.Monitors[I].Top+Screen.Monitors[I].Height then
    frmDarkDesktop.Height:=Screen.Monitors[I].Top+Screen.Monitors[I].Height-frmDarkDesktop.Top;
  end;
end
else frmDarkDesktop.WindowState:=wsMaximized;

  frmDarkDesktop.FormStyle:=fsStayOnTop;

  // creamos el icono del programa
  fwm_TaskbarRestart := RegisterWindowMessage('DarkTrayCreated');
  IconoTray := TIcon.Create;
  ImageList1.GetIcon(1,IconoTray);
  with IconData do
  begin
    cbSize:=IconData.SizeOf;
  //  sizeof(IconData);
    wnd:=handle;
    Uid:=100;
    uFlags:=NIF_MESSAGE+NIF_ICON+NIF_TIP;
    uCallbackMessage:=WM_USER+1;
    hIcon:=IconoTray.Handle; //Application.Icon.Handle;
    StrPCopy(szTip,'DarkDesktop')
  end;
  Shell_NotifyIcon(NIM_ADD,@IconData);

  //Valores por defecto por si ini write falla
  Opacity:=128;
  OpInterval:=15;
  OpPersistentInterval:=1000;
  OpPersistent:=true;
  OpShowOSD:=true;
  currentMouseX:=Mouse.CursorPos.X;
  // Leemos datos de inicialización
  ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'config.ini');
  try
    if not FileExists(ExtractFilePath(Application.ExeName)+'config.ini')then
    ini.WriteInteger('Settings','Opacity',128);
    Opacity:=ini.ReadInteger('Settings','Opacity',128);
    OpInterval:=ini.ReadInteger('Settings','Interval',15);
    OpPersistentInterval:=ini.ReadInteger('Settings','Persist',1000);
    OpPersistent:=ini.ReadBool('Settings','Persistent',true);
    OpShowOSD:=ini.ReadBool('Settings','Indicator',true);
  finally
    ini.Free;
  end;
  timer1.Enabled:=OpPersistent;
  timer1.Interval:=OpPersistentInterval;
  //Aplicamos oscurecimiento
  //SetWindowLong(form1.Handle,GWL_EXSTYLE,GWL)
   SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) Or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOOLWINDOW {and not WS_EX_APPWINDOW});
   SetLayeredWindowAttributes(Handle,0,opacity, LWA_ALPHA);

   SetWindowPos(Handle,HWND_TOPMOST,Left,Top,Width, Height,SWP_NOMOVE or SWP_NOACTIVATE or SWP_NOSIZE);

  //for dual monitors or more
  {GetWindowRect(handle,rc);
  rc.Right:=GetSystemMetrics(SM_CXSCREEN);
  rc.Bottom:=GetSystemMetrics(SM_CYSCREEN);
  SystemParametersInfo(SPI_GETWORKAREA,0,@rc,0);}
  //if t.Top=0 then
  //SetBounds(rc.Left,22,r.Right-r.Left,screen.height-80);//r.Bottom-r.Top);

  //verificamos si es autoejecutable junto con windows

  AutoStartState;

  //ocultamos el form de alt+tab

  ///ahora aplicamos los hotkeys
  if(not RegisterHotKey(self.Handle,GlobalAddAtom('ALT_PLUS'),MOD_CONTROL+MOD_ALT,VK_ADD)) then
  begin
    ShowMessage('Error! Alt_+ ya está siendo utilizado');
    if GlobalFindAtom('ALT_PLUS')<>0 then
      UnregisterHotKey(Self.Handle,GlobalFindAtom('ALT_PLUS'));
  end;

  if(not RegisterHotKey(self.Handle,GlobalAddAtom('ALT_LESS'),MOD_CONTROL+MOD_ALT,VK_SUBTRACT)) then
  begin
    ShowMessage('Error! Alt_- ya está siendo utilizado');
    if GlobalFindAtom('ALT_LESS')<>0 then
      UnregisterHotKey(Self.Handle,GlobalFindAtom('ALT_LESS'));
  end;

//  if(not RegisterHotKey(self.Handle, GlobalAddAtom('CTRL_WIN_ALT'),MOD_WIN,ORD('n'))) then
  if(not RegisterHotKey(self.Handle, GlobalAddAtom('CTRL_WIN_ALT'),MOD_CONTROL+MOD_ALT,ORD('Z'))) then
  begin
    ShowMessage('Error! Ctrl+Alt+Z ya está siendo utilizado');
    if GlobalFindAtom('CTRL_WIN_ALT')<> 0 then
      UnregisterHotKey(Self.Handle,GlobalFindAtom('CTRL_WIN_ALT'));
  end;

  if (not RegisterHotKey(self.Handle, GlobalAddAtom('DISABLEWIN'),MOD_CONTROL+MOD_ALT,ORD('X'))) then
  begin
    ShowMessage('Error! Ctrl+Alt+X ya está siendo utilizado');
    if GlobalFindAtom('DISABLEWIN')<> 0 then
      UnregisterHotKey(Self.Handle,GlobalFindAtom('DISABLEWIN'));
  end;

  //idioma del usuario

  //creamos el bitmap basado en el actual tamaño de la ventana
  BmpMask.Width := Width;
  BmpMask.Height := Height;
  BmpMask.DrawMode := dmBlend;
  BmpMask.FillRectS(BmpMask.BoundsRect, clRed32);

  //Image321.Bitmap:=BmpMask;
  Image321.Visible := False;

  BmpPos := Point(0,0);
  BmpSize.cx := BmpMask.Width;
  BmpSize.cy := BmpMask.Height;

  BlendFunc.BlendOp := AC_SRC_OVER;
  BlendFunc.BlendFlags := 0;
  BlendFunc.SourceConstantAlpha := 255;
  BlendFunc.AlphaFormat := 0;

  UpdateLayeredWindow(Self.Handle, 0, nil, @BmpSize, BmpMask.Handle, @BmpPos, 0, @blendfunc, ULW_ALPHA);

  DoubleBuffered := True;


end;

procedure TfrmDarkDesktop.FormDestroy(Sender: TObject);
begin
  if IconData.Wnd <>0 then Shell_NotifyIcon(NIM_DELETE,@IconData);
  if GlobalFindAtom('ALT_PLUS')<>0 then
    UnregisterHotKey(handle,GlobalFindAtom('ALT_PLUS'));
  if GlobalFindAtom('ALT_LESS')<>0 then
    UnregisterHotKey(handle,GlobalFindAtom('ALT_LESS'));
  if GlobalFindAtom('CTRL_WIN_ALT')<>0 then
    UnregisterHotKey(handle,GlobalFindAtom('CTRL_WIN_ALT'));
  if GlobalFindAtom('DISABLEWIN')<> 0 then
    UnregisterHotKey(Self.Handle,GlobalFindAtom('DISABLEWIN'));

  IconoTray.Free;
  BmpMask.Free;
end;

procedure TfrmDarkDesktop.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
//  Shape1.Left := X - Shape1.Width div 2;
//  Shape1.Top := Y - Shape1.Height div 2;
end;

procedure TfrmDarkDesktop.FormResize(Sender: TObject);
begin
  if Width >= Height then
  begin
    Image321.Height := Height;
    Image321.Width := Height;
    Image321.Left := (Width - Image321.Width) div 2;
  end
  else
  begin
    Image321.Width := Width;
    Image321.Height := Width;
    Image321.Top := (Height - Image321.Height) div 2;
  end;
end;

procedure TfrmDarkDesktop.FormShow(Sender: TObject);
begin
ShowWindow(application.Handle, SW_HIDE);
end;

procedure TfrmDarkDesktop.Salir1Click(Sender: TObject);
begin
close
end;

procedure TfrmDarkDesktop.Acercade1Click(Sender: TObject);
begin
with TFormSplash.Create(application)do
execute;
end;

procedure TfrmDarkDesktop.Configuracin1Click(Sender: TObject);
begin
timer1.Enabled:=false;
frmSettings.Show//Modal
end;

procedure RegAutoStart;
var
key: string;
reg: TRegIniFile;
begin
key:='\Software\Microsoft\Windows\CurrentVersion\Run';
reg:=TRegIniFile.Create;
try
  reg.RootKey:=HKEY_CURRENT_USER;
  reg.CreateKey(key);
  if reg.OpenKey(Key,False) then reg.WriteString(key,'DarkDesktop',pchar(Application.exename));
finally
  reg.Free;
end;
end;

procedure UnRegAutoStart;
var key: string;
     Reg: TRegIniFile;
begin
  key := '\Software\Microsoft\Windows\CurrentVersion\Run';
  Reg:=TRegIniFile.Create;
try
  Reg.RootKey:=HKEY_CURRENT_USER;
  if Reg.OpenKey(Key,False) then Reg.DeleteValue('DarkDesktop');
  finally
  Reg.Free;
  end;
end;

procedure TfrmDarkDesktop.IniciarjuntoconWindows1Click(Sender: TObject);
begin
if IniciarjuntoconWindows1.Checked then
begin
UnRegAutoStart;
IniciarjuntoconWindows1.Checked:=false;
end
else
begin
RegAutoStart;
IniciarjuntoconWindows1.Checked:=true;
end;
end;

function IsWindowOnTop(hWindow: HWND): Boolean; 
begin 
  Result := (GetWindowLong(hWindow, GWL_EXSTYLE) and WS_EX_TOPMOST) <> 0 
end;

procedure TfrmDarkDesktop.Timer1Timer(Sender: TObject);
begin
//form1.color:=Random(255);
//  form1.Hide;
//    Application.BringToFront;
try
if frmSettings.Showing then timer1.Enabled:=false;
except
end;
//if (OpPersistent) and (not FormSplash.Showing) then

if (OpPersistent) then
try
  frmDarkDesktop.Show;
except
end;

{  if not IsWindowOnTop(FindWindow('DarkDesktopClass',nil))then
  begin
    SetWindowPos(Handle,HWND_TOPMOST,Left,Top,Width, Height,SWP_NOMOVE or SWP_NOACTIVATE or SWP_NOSIZE);
  end;}

end;

procedure TfrmDarkDesktop.Timer2Timer(Sender: TObject);
begin
try
frmDarkDesktop.lblOpacityChange.Visible:=false;
timer2.Enabled:=false;
except
end;
end;

procedure TfrmDarkDesktop.tmrClockTimer(Sender: TObject);
function IntToTimeStr(var timepart: word; docehoras: boolean = false):string;
var
  strtime: string;
begin
  strtime := IntToStr(timepart);
  if docehoras then
  begin
    if timepart > 12 then
    strtime := IntToStr(timepart - 12);
  end;

  if strtime.Length = 1 then
  strtime := '0'+strtime;

  Result := strtime;
end;
var
  Hora : TSystemTime;

begin
  UpdateClockPosition;
  GetLocalTime(Hora);
  lblClock.Caption := IntToTimeStr(Hora.wHour,True)+':'+IntToTimeStr(Hora.wMinute)+':'+IntToTimeStr(Hora.wSecond); //DateTimeToStr(SystemTimeToDateTime(Hora));
end;

procedure TfrmDarkDesktop.tmrCrHaloTimer(Sender: TObject);
var
  P: TPoint;
begin
  try
    P := ScreenToClient(Mouse.CursorPos);

    Shape1.Left := P.X - Shape1.Width div 2;
    Shape1.Top  := P.Y - Shape1.Height div 2;
  except

  end;
end;

procedure TfrmDarkDesktop.tmrWorkAreaMonitorTimer(Sender: TObject);
begin
  if Screen.WorkAreaWidth <> ActualWorkAreaWidth then
  begin
    ActualWorkAreaWidth := Screen.WorkAreaWidth;
    Width := ActualWorkAreaWidth;
  end;
end;

procedure TfrmDarkDesktop.Desactivar1Click(Sender: TObject);
begin
    if Timer1.Enabled then begin
      frmDarkDesktop.Hide;
      Desactivar1.Caption:='&Activar';
      Timer1.Enabled:=false;
      ImageList1.GetIcon(0, IconoTray);
      IconData.hIcon := IconoTray.Handle;
      Shell_NotifyIcon(NIM_MODIFY,@IconData);
    end
    else begin
      frmDarkDesktop.Show;
      Desactivar1.Caption:='&Desactivar';
      Timer1.Enabled:=true;
      ImageList1.GetIcon(1, IconoTray);
      IconData.hIcon := IconoTray.Handle;
      Shell_NotifyIcon(NIM_MODIFY,@IconData);
    end;
end;

end.
