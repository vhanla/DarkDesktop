{
DarkDesktop settings window

A software based brightness control for Windows 7 machines
only desktop application non Fullscreen DirectX support

CHANGELOG:


 2014-12-13
  chkCrHalo - to enable or disable cursor halo

 2014-12-06
  Added UpdatePosition
  Added CreateParams in order to convert the bsNone styled window to thickframe
  Added WMNCHitTest in order to avoid resizing the thickframe window
  Added CloseWindow in order to assign it to close window if lost focus
  Added SetWindowLong procedure in FormCreate in order to hide this window from the taskbar
}
unit Settings;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, XPMan, jpeg, ExtCtrls, Inifiles, Spin,
  Vcl.Imaging.pngimage;

type
  TfrmSettings = class(TForm)
    Image1: TImage;
    XPManifest1: TXPManifest;
    TrackBar1: TTrackBar;
    Label1: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    lblOpacity: TLabel;
    spinPersistent: TSpinEdit;
    chkPersistent: TCheckBox;
    lblPersistent: TLabel;
    chkIndicator: TCheckBox;
    spinInterval: TSpinEdit;
    Label2: TLabel;
    chkClock: TCheckBox;
    rbClock1: TRadioButton;
    rbClock2: TRadioButton;
    rbClock3: TRadioButton;
    rbClock4: TRadioButton;
    rbClock5: TRadioButton;
    rbClock6: TRadioButton;
    rbClock7: TRadioButton;
    rbClock8: TRadioButton;
    rbClock9: TRadioButton;
    Image2: TImage;
    Button1: TButton;
    chkCrHalo: TCheckBox;
    chkShowForeground: TCheckBox;
    chkCaretHalo: TCheckBox;
    ColorDialog1: TColorDialog;
    ColorBox1: TColorBox;
    Button2: TButton;
    Label3: TLabel;
    chkColorize: TCheckBox;
    spHaloRadio: TSpinEdit;
    spCaretRadio: TSpinEdit;
    procedure btnCancelClick(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure chkPersistentClick(Sender: TObject);
    procedure chkClockClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure UpdatePosition;
    procedure rbClock7Click(Sender: TObject);
    procedure rbClock4Click(Sender: TObject);
    procedure rbClock1Click(Sender: TObject);
    procedure rbClock2Click(Sender: TObject);
    procedure rbClock5Click(Sender: TObject);
    procedure rbClock8Click(Sender: TObject);
    procedure rbClock3Click(Sender: TObject);
    procedure rbClock6Click(Sender: TObject);
    procedure rbClock9Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure chkCrHaloClick(Sender: TObject);
    procedure chkCaretHaloClick(Sender: TObject);
    procedure chkShowForegroundClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ColorBox1Change(Sender: TObject);
    procedure chkColorizeClick(Sender: TObject);
  private
    { Private declarations }
    procedure CreateParams(var Params: TCreateParams);override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); Message WM_NCHITTEST;
    procedure CloseWindow(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmSettings: TfrmSettings;
  Opacity2: Integer;
  changed: boolean;
implementation

uses DarkDesktop_src;

{$R *.dfm}

procedure TfrmSettings.btnCancelClick(Sender: TObject);
begin
//SetLayeredWindowAttributes(frmDarkDesktop.Handle,0,Opacity2, LWA_ALPHA);
frmDarkDesktop.AlphaBlendValue := Opacity2;
TrackBar1.Position:=Opacity2;
close
end;

procedure TfrmSettings.TrackBar1Change(Sender: TObject);
begin
//SetLayeredWindowAttributes(frmDarkDesktop.Handle,0,TrackBar1.Position, LWA_ALPHA);
frmDarkDesktop.AlphaBlendValue := TrackBar1.Position;
lblOpacity.Caption:=IntToStr(TrackBar1.Position);
end;

procedure TfrmSettings.btnOKClick(Sender: TObject);
var
ini: TIniFile;
begin
  ini:=TIniFile.Create(DarkDesktop_src.ConfigIniPath);
  try
    ini.WriteInteger('Settings','Opacity',TrackBar1.Position);
    Opacity2:=TrackBar1.Position;
    //intervalo de cambio
    ini.WriteInteger('Settings','Interval',spinInterval.Value);
    //intervalo de persistencia
    ini.WriteInteger('Settings','Persist',spinPersistent.Value);
    ini.WriteBool('Settings','Persistent',chkPersistent.Checked);
    ini.WriteBool('Settings','Indicator',chkIndicator.Checked);

    // new features
    ini.WriteBool('Settings','ShowClock',chkClock.Checked);
    ini.WriteBool('Settings','ShowHalo', chkCrHalo.Checked);
    ini.WriteInteger('Settings', 'MouseHaloRadio', spHaloRadio.Value);
    ini.WriteBool('Settings', 'CaretHalo', chkCaretHalo.Checked);
    ini.WriteInteger('Settings', 'CaretHaloRadio', spCaretRadio.Value);
    ini.WriteBool('Settings', 'ShowForeground', chkShowForeground.Checked);
    ini.WriteString('Settings', 'Color', TColorToHex(OpColor));
    ini.WriteBool('Settings', 'InteractiveColor', chkColorize.Checked);
    if rbClock1.Checked then
      ini.WriteInteger('Settings','ClockPosition',1)
    else if rbClock2.Checked then
      ini.WriteInteger('Settings','ClockPosition',2)
    else if rbClock3.Checked then
      ini.WriteInteger('Settings','ClockPosition',3)
    else if rbClock4.Checked then
      ini.WriteInteger('Settings','ClockPosition',4)
    else if rbClock5.Checked then
      ini.WriteInteger('Settings','ClockPosition',5)
    else if rbClock6.Checked then
      ini.WriteInteger('Settings','ClockPosition',6)
    else if rbClock7.Checked then
      ini.WriteInteger('Settings','ClockPosition',7)
    else if rbClock8.Checked then
      ini.WriteInteger('Settings','ClockPosition',8)
    else if rbClock9.Checked then
      ini.WriteInteger('Settings','ClockPosition',9);

  finally
    ini.Free;
  end;

  //aplicamos los cambios a darkdesktop
  OpInterval:=spinInterval.Value;
  OpPersistentInterval:=spinPersistent.Value;
  OpPersistent:=chkPersistent.Checked;
  OpShowOSD:=chkIndicator.Checked;
  OpCaretHalo := chkCaretHalo.Checked;
  OpShowForeground := chkShowForeground.Checked;
  OpInteractiveColor := chkColorize.Checked;
  frmDarkDesktop.Timer1.Interval:=OpPersistentInterval;
  frmDarkDesktop.Shape1.Width := spHaloRadio.Value * 2;
  frmDarkDesktop.Shape1.Height := spHaloRadio.Value * 2;
  frmDarkDesktop.shpCaretHalo.Width := spCaretRadio.Value * 2;
  frmDarkDesktop.shpCaretHalo.Height := spCaretRadio.Value * 2;

  close
end;

procedure TfrmSettings.Button1Click(Sender: TObject);
begin
  if Button1.Caption = 'Block me' then
  begin
    Button1.Caption := 'Unblock me';
    SetWindowLong(frmDarkDesktop.Handle, GWL_EXSTYLE, GetWindowLong(frmDarkDesktop.Handle, GWL_EXSTYLE) and not WS_EX_TRANSPARENT);
  end
  else
  begin
    Button1.Caption := 'Block me';
    SetWindowLong(frmDarkDesktop.Handle, GWL_EXSTYLE, GetWindowLong(frmDarkDesktop.Handle, GWL_EXSTYLE) or WS_EX_TRANSPARENT);
  end;
end;

procedure TfrmSettings.Button2Click(Sender: TObject);
begin
  ColorDialog1.Options := [cdFullOpen, cdAnyColor];
  if ColorDialog1.Execute then
  begin
    ColorBox1.Selected := ColorDialog1.Color;
    OpColor := ColorDialog1.Color;
    frmDarkDesktop.Color := ColorDialog1.Color;
  end;
end;

procedure TfrmSettings.chkShowForegroundClick(Sender: TObject);
begin
  OpShowForeground := chkShowForeground.Checked;
  if OpShowForeground then
    SetForegroundBackground(frmDarkDesktop.Handle);
end;

procedure TfrmSettings.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//form1.FormStyle:=fsStayOnTop;
// SetWindowLong(form1.Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) Or WS_EX_LAYERED or WS_EX_TRANSPARENT);
  if Opacity2 <> TrackBar1.Position then
  begin
    //SetLayeredWindowAttributes(frmDarkDesktop.Handle,0,Opacity2, LWA_ALPHA);
    frmDarkDesktop.AlphaBlendValue := Opacity2;
    TrackBar1.Position:=Opacity2;
  end;

  if OpPersistent then frmDarkDesktop.Timer1.Enabled:=true;
  if OpShowForeground then begin
    frmDarkDesktop.Show;
    frmDarkDesktop.Timer1.Enabled := False;
    frmDarkDesktop.tmrShowForeground.Enabled := True;
  end;

end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  Application.OnDeactivate := CloseWindow;
  SetWindowLong(Self.Handle, GWL_EXSTYLE,
    GetWindowLong(Self.Handle, GWL_EXSTYLE) and not WS_EX_APPWINDOW
    or WS_EX_TOOLWINDOW);
end;

procedure TfrmSettings.FormShow(Sender: TObject);
var
ini: TIniFile;
begin
  frmDarkDesktop.Timer1.Enabled := False;
  frmDarkDesktop.tmrShowForeground.Enabled := False;
  //form1.FormStyle:=fsNormal;
  ini:=TIniFile.Create(DarkDesktop_src.ConfigIniPath);
  try
    if not FileExists(DarkDesktop_src.ConfigIniPath)then
    ini.WriteInteger('Settings','Opacity',128);
    opacity2:=ini.ReadInteger('Settings','Opacity',128);
    TrackBar1.Position:=Opacity2;
    spinInterval.Value:=ini.ReadInteger('Settings','Interval',15);
    chkIndicator.Checked:=ini.ReadBool('Settings','Indicator',true);
    chkPersistent.Checked:=ini.ReadBool('Settings','Persistent',true);
    spinPersistent.Value:=ini.ReadInteger('Settings','Persist',1000);
    chkClock.Checked := ini.ReadBool('Settings','ShowClock',False);
    //chkClockClick(Sender);
    chkCrHalo.Checked := ini.ReadBool('Settings','ShowHalo', False);
    //chkCrHaloClick(Sender);
    chkCaretHalo.Checked := OpCaretHalo;
    //chkCaretHaloClick(Sender);
    chkShowForeground.Checked := OpShowForeground;
    chkColorize.Checked := OpInteractiveColor;
    ColorBox1.Selected := OpColor;
    spHaloRadio.Value := ini.ReadInteger('Settings', 'MouseHaloRadio', 100);
    spCaretRadio.Value := ini.ReadInteger('Settings', 'CaretHaloRadio', 100);
    //chkShowForegroundClick(Sender);
    case ini.ReadInteger('Settings','ClockPosition',7) of
      1: rbClock1.Checked := True;
      2: rbClock2.Checked := True;
      3: rbClock3.Checked := True;
      4: rbClock4.Checked := True;
      5: rbClock5.Checked := True;
      6: rbClock6.Checked := True;
      7: rbClock7.Checked := True;
      8: rbClock8.Checked := True;
      9: rbClock9.Checked := True;
    end;
  finally
    ini.Free;
  end;
  lblOpacity.Caption:=IntToStr(TrackBar1.Position);

end;

procedure TfrmSettings.rbClock1Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.rbClock2Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.rbClock3Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.rbClock4Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.rbClock5Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.rbClock6Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.rbClock7Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.rbClock8Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.rbClock9Click(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
end;

procedure TfrmSettings.chkCaretHaloClick(Sender: TObject);
begin
  frmDarkDesktop.tmrCaretHalo.Enabled := chkCaretHalo.Checked;
end;

procedure TfrmSettings.chkClockClick(Sender: TObject);
begin
  frmDarkDesktop.UpdateClockPosition;
  frmDarkDesktop.tmrClock.Enabled := chkClock.Checked;
  frmDarkDesktop.lblClock.Visible := chkClock.Checked;
end;

procedure TfrmSettings.chkColorizeClick(Sender: TObject);
begin
  frmDarkDesktop.tmrColorize.Enabled := chkColorize.Checked;
  if not chkColorize.Checked then
    frmDarkDesktop.Color := ColorBox1.Selected;
end;

procedure TfrmSettings.chkCrHaloClick(Sender: TObject);
begin
  frmDarkDesktop.tmrCrHalo.Enabled := chkCrHalo.Checked;
  frmDarkDesktop.Shape1.Visible := chkCrHalo.Checked;
end;

procedure TfrmSettings.chkPersistentClick(Sender: TObject);
begin
  spinPersistent.Visible:=chkPersistent.Checked;
  lblPersistent.Visible:=chkPersistent.Checked;
end;



procedure TfrmSettings.UpdatePosition;
var
  Shell_TrayWnd : HWND;
  Shell_TrayWndRect : TRect;

begin
  Shell_TrayWnd := FindWindow('Shell_TrayWnd', nil);
  if Shell_TrayWnd <= 0 then
    Exit;

  GetWindowRect(Shell_TrayWnd, Shell_TrayWndRect);

  begin
    if (Shell_TrayWndRect.Left=0)
      and(Shell_TrayWndRect.Right=Screen.WorkAreaWidth)
      and(Shell_TrayWndRect.Top>0)
      then
      begin
      //ShowMessage('está abajo')
      //posicionamos a la derecha en el systray
      Left:=Screen.WorkAreaWidth-Width-10;
      if Left<1 then Left:=10;
      Top:=Screen.WorkAreaHeight-Height{-Shell_TrayWndRect.Bottom+Shell_TrayWndRect.Top}-10;
      if Top<1 then Top:=10;
      end
      //arriba
      else if (Shell_TrayWndRect.Left=0)
      and(Shell_TrayWndRect.Right=Screen.WorkAreaWidth)
      and(Shell_TrayWndRect.Top<1)
      then
      begin
      //ShowMessage('Está arriba');
      Left:=Screen.WorkAreaWidth-Width-10;
      if Left<1 then Left:=10;
      Top:=Shell_TrayWndRect.Bottom+10;
      if Top<1 then Top:=10;
      end
      //izquierda
      else if (Shell_TrayWndRect.Left<1)
      and (Shell_TrayWndRect.Top=0)
      and(Shell_TrayWndRect.Bottom=Screen.WorkAreaHeight)
      then
      begin
      //ShowMessage('Está a la izquierda')
      Left:=Shell_TrayWndRect.Right+10;
      if Left<1 then Left:=10;
      Top:=Screen.WorkAreaHeight-Height-10;
      if Top<1 then Top:=10;
      end
      //derecha
      else if (Shell_TrayWndRect.Left>0)
      and(Shell_TrayWndRect.Top=0)
      and(Shell_TrayWndRect.Bottom=Screen.WorkAreaHeight)
      then
      begin
      //ShowMessage('Está a la derecha');
      Left:=Shell_TrayWndRect.Left-Width-10;
      if Left<1 then Left:=10;
      Top:=Screen.WorkAreaHeight-Height-10;
      if Top<1 then Top:=10;
      end;
  end;
end;

procedure TfrmSettings.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle:=Params.ExStyle and not WS_EX_TOOLWINDOW or WS_EX_APPWINDOW;
  Params.Style := Params.Style or WS_THICKFRAME;
end;

procedure TfrmSettings.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Inherited;
  with Message do
  begin
    if (Result = HTBOTTOM)
    or (Result = HTBOTTOMLEFT)
    or (Result = HTBOTTOMRIGHT)
    or (Result = HTLEFT)
    or (Result = HTRIGHT)
    or (Result = HTTOP)
    or (Result = HTTOPLEFT)
    or (Result = HTTOPRIGHT)
    then Result := HTBORDER;
  end;
end;

procedure TfrmSettings.CloseWindow(Sender: TObject);
begin
  Hide;
end;

procedure TfrmSettings.ColorBox1Change(Sender: TObject);
begin
  frmDarkDesktop.Color := ColorBox1.Selected;
end;

end.
