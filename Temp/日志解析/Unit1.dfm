object Form1: TForm1
  Left = 192
  Top = 161
  Width = 1305
  Height = 675
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 12
  object Memo1: TMemo
    Left = 0
    Top = 41
    Width = 761
    Height = 595
    Align = alLeft
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1289
    Height = 41
    Align = alTop
    Caption = 'Panel1'
    TabOrder = 1
    DesignSize = (
      1289
      41)
    object Btn1: TButton
      Left = 16
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Btn1'
      TabOrder = 0
      OnClick = Btn1Click
    end
    object PBar1: TProgressBar
      Left = 120
      Top = 16
      Width = 1145
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
  end
end
