object fFormSimle: TfFormSimle
  Left = 634
  Top = 350
  Width = 365
  Height = 228
  BorderIcons = [biSystemMenu, biMinimize]
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object dxLayoutControl1: TdxLayoutControl
    Left = 0
    Top = 0
    Width = 349
    Height = 189
    Align = alClient
    TabOrder = 0
    TabStop = False
    AutoContentSizes = [acsWidth, acsHeight]
    LookAndFeel = FDM.dxLayoutWeb1
    object BtnOK: TcxButton
      Left = 203
      Top = 156
      Width = 65
      Height = 22
      Caption = #20445#23384
      TabOrder = 4
      OnClick = BtnOKClick
    end
    object BtnExit: TcxButton
      Left = 273
      Top = 156
      Width = 65
      Height = 22
      Caption = #21462#28040
      ModalResult = 2
      TabOrder = 5
    end
    object EditTruck: TcxTextEdit
      Left = 81
      Top = 36
      ParentFont = False
      TabOrder = 0
      Width = 121
    end
    object EditXH: TcxTextEdit
      Left = 81
      Top = 61
      ParentFont = False
      TabOrder = 1
      Width = 121
    end
    object EditType: TcxComboBox
      Left = 81
      Top = 86
      ParentFont = False
      Properties.DropDownListStyle = lsEditFixedList
      Properties.ItemHeight = 20
      Properties.Items.Strings = (
        'VMAS'
        #21452#24608#36895)
      TabOrder = 2
      Width = 121
    end
    object Check1: TcxCheckBox
      Left = 11
      Top = 156
      Caption = #40657#21517#21333#26679#26412
      ParentFont = False
      TabOrder = 3
      Transparent = True
      Width = 94
    end
    object dxLayoutControl1Group_Root: TdxLayoutGroup
      ShowCaption = False
      Hidden = True
      ShowBorder = False
      object dxLayoutControl1Group1: TdxLayoutGroup
        AutoAligns = [aaHorizontal]
        AlignVert = avClient
        Caption = #26679#26412
        object dxLayoutControl1Item3: TdxLayoutItem
          Caption = #36710' '#29260' '#21495':'
          Control = EditTruck
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item4: TdxLayoutItem
          Caption = #26816#27979#27969#27700':'
          Control = EditXH
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item5: TdxLayoutItem
          Caption = #26816#27979#31867#22411':'
          Control = EditType
          ControlOptions.ShowBorder = False
        end
      end
      object dxLayoutControl1Group3: TdxLayoutGroup
        AutoAligns = [aaVertical]
        AlignHorz = ahClient
        ShowCaption = False
        Hidden = True
        LayoutDirection = ldHorizontal
        ShowBorder = False
        object dxLayoutControl1Item6: TdxLayoutItem
          Caption = #40657#21517#21333#26679#26412
          ShowCaption = False
          Control = Check1
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item1: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahRight
          Caption = 'cxButton1'
          ShowCaption = False
          Control = BtnOK
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item2: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahRight
          Caption = 'cxButton2'
          ShowCaption = False
          Control = BtnExit
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
