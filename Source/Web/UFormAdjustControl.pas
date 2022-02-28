{*******************************************************************************
  作者: dmzn@163.com 2022-02-25
  描述: 添加车辆
*******************************************************************************}
unit UFormAdjustControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UFormNormal, uniButton, unimButton,
  uniGUIClasses, uniEdit, unimEdit, uniGUIBaseClasses, uniGUImJSForm,
  System.Classes, uniPanel, uniMemo, unimPanel, unimMemo, uniCheckBox,
  unimCheckBox, uniLabel, unimLabel, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient;

type
  TfFormAdjustControl = class(TfFormNormal)
    PanelTool: TUnimContainerPanel;
    PanelR: TUnimContainerPanel;
    PanelC: TUnimContainerPanel;
    PanelL: TUnimContainerPanel;
    BtnOpen: TUnimButton;
    LabelStatus: TUnimLabel;
    BtnClose: TUnimButton;
    BtnFresh: TUnimButton;
    LabelHint: TUnimLabel;
    procedure BtnFreshClick(Sender: TObject);
    procedure BtnOpenClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
  private
    { Private declarations }
    procedure SendControl(const nType: Byte = 0);
    procedure ShowStatus(const nStatus: string; const nHint: Boolean = False);
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}
uses
  IdGlobal, MainModule, UManagerGroup, ULibFun, USysBusiness, USysDB;

procedure TfFormAdjustControl.ShowStatus(const nStatus: string;
  const nHint: Boolean);
begin
  if nHint then
  begin
    LabelHint.Caption := nStatus;
    LabelStatus.Caption := '状态: ';
  end else
  begin
    LabelHint.Caption := '';
    LabelStatus.Caption := nStatus;
  end;
end;

procedure TfFormAdjustControl.SendControl(const nType: Byte);
var nStr: string;
begin
  with UniMainModule.TCPClient1 do
  try
    if not Connected then
      Connect();
    //xxxxx

    if nType = 1 then //开启校正
    begin
      nStr := 'CMD_AdjustControl=' + sFlag_Yes;
      IOHandler.WriteLn(TEncodeHelper.EncodeBase64(nStr));
    end else

    if nType = 2 then //关闭校正
    begin
      nStr := 'CMD_AdjustControl=' + sFlag_No;
      IOHandler.WriteLn(TEncodeHelper.EncodeBase64(nStr));
    end;

    IOHandler.CheckForDataOnSource(20);
    if not IOHandler.InputBufferIsEmpty then
      IOHandler.InputBuffer.Clear;
    //clear buffer first

    nStr := 'CMD_AdjustControl=Status';
    IOHandler.WriteLn(TEncodeHelper.EncodeBase64(nStr));
    nStr := TEncodeHelper.DecodeBase64(IOHandler.ReadLn());

    if Pos('CMD_AdjustControl=', nStr) = 1 then
    begin
      System.Delete(nStr, 1, Pos('=', nStr));
      if nStr = sFlag_Enabled then
           nStr := '正常校正'
      else nStr := '校正关闭';

      ShowStatus('当前: ' + nStr);
    end else
    begin
      ShowStatus('获取状态失败', True);
    end;
  except
    on nErr: Exception do
    begin
      ShowStatus(nErr.Message, True);
      Disconnect();
    end;
  end;
end;

procedure TfFormAdjustControl.BtnFreshClick(Sender: TObject);
begin
  SendControl(0);
end;

procedure TfFormAdjustControl.BtnOpenClick(Sender: TObject);
begin
  SendControl(1);
end;

procedure TfFormAdjustControl.BtnCloseClick(Sender: TObject);
begin
  SendControl(2);
end;

initialization
  RegisterClass(TfFormAdjustControl);
end.
