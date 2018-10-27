object fFormMemo: TfFormMemo
  Left = 634
  Top = 350
  Width = 434
  Height = 441
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
    Width = 418
    Height = 402
    Align = alClient
    TabOrder = 0
    TabStop = False
    AutoContentSizes = [acsWidth, acsHeight]
    LookAndFeel = FDM.dxLayoutWeb1
    object BtnOK: TcxButton
      Left = 272
      Top = 369
      Width = 65
      Height = 22
      Caption = #20445#23384
      TabOrder = 4
      OnClick = BtnOKClick
    end
    object BtnExit: TcxButton
      Left = 342
      Top = 369
      Width = 65
      Height = 22
      Caption = #21462#28040
      ModalResult = 2
      TabOrder = 5
    end
    object EditTrucks: TcxMemo
      Left = 23
      Top = 36
      ParentFont = False
      Properties.ScrollBars = ssBoth
      Style.Edges = []
      TabOrder = 0
      Height = 89
      Width = 185
    end
    object Check1: TcxCheckBox
      Left = 11
      Top = 369
      Caption = #21152#20837#40657#21517#21333
      ParentFont = False
      TabOrder = 3
      Transparent = True
      Width = 116
    end
    object EditSimple: TcxComboBox
      Left = 81
      Top = 337
      ParentFont = False
      Properties.DropDownRows = 20
      Properties.IncrementalSearch = False
      Properties.ItemHeight = 18
      TabOrder = 2
      OnKeyDown = EditSimpleKeyDown
      Width = 121
    end
    object EditType: TcxComboBox
      Left = 81
      Top = 312
      ParentFont = False
      Properties.DropDownListStyle = lsEditFixedList
      Properties.DropDownRows = 20
      Properties.ItemHeight = 18
      Properties.Items.Strings = (
        '1.VMAS'
        '2.'#21452#24608#36895)
      Properties.OnEditValueChanged = EditTypePropertiesEditValueChanged
      TabOrder = 1
      Width = 121
    end
    object dxLayoutControl1Group_Root: TdxLayoutGroup
      ShowCaption = False
      Hidden = True
      ShowBorder = False
      object dxLayoutControl1Group1: TdxLayoutGroup
        AutoAligns = [aaHorizontal]
        AlignVert = avClient
        Caption = #36710#29260#21495
        object dxLayoutControl1Item3: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Caption = 'cxMemo1'
          ShowCaption = False
          Control = EditTrucks
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item6: TdxLayoutItem
          Caption = #26679#26412#31867#22411':'
          Control = EditType
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item5: TdxLayoutItem
          Caption = #26816#27979#26679#26412':'
          Control = EditSimple
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
        object dxLayoutControl1Item4: TdxLayoutItem
          Caption = 'cxCheckBox1'
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
