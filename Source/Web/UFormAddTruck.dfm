inherited fFormAddTruck: TfFormAddTruck
  Caption = #28155#21152#36710#36742
  OnCreate = UnimFormCreate
  PixelsPerInch = 96
  TextHeight = 13
  ScrollPosition = 0
  ScrollHeight = 47
  PlatformData = {}
  object EditTrucks: TUnimMemo
    Left = 0
    Top = 0
    Width = 320
    Height = 435
    Hint = ''
    Align = alClient
    EmptyText = #36755#20837' '#25110' '#31896#36148#36710#36742#21015#34920
    TabOrder = 0
    ExplicitHeight = 432
  end
  object PanelTool: TUnimContainerPanel
    Left = 0
    Top = 435
    Width = 320
    Height = 45
    Hint = ''
    Align = alBottom
    AlignmentControl = uniAlignmentClient
    Layout = 'hbox'
    object PanelL: TUnimContainerPanel
      Left = 0
      Top = 0
      Width = 105
      Height = 45
      Hint = ''
      Align = alLeft
      Layout = 'hbox'
      LayoutAttribs.Align = 'center'
      LayoutAttribs.Pack = 'center'
      Flex = 3
      ExplicitHeight = 56
      object Check1: TUnimCheckBox
        Left = 2
        Top = 5
        Width = 92
        Height = 35
        Hint = ''
        FieldLabel = #40657#21517#21333
        FieldLabelAlign = laRight
        FieldLabelWidth = 80
        Caption = #40657#21517#21333
      end
    end
    object PanelC: TUnimContainerPanel
      Left = 105
      Top = 0
      Width = 150
      Height = 45
      Hint = ''
      Align = alClient
      LayoutAttribs.Align = 'center'
      LayoutAttribs.Pack = 'center'
      Flex = 4
      ExplicitLeft = 8
      ExplicitWidth = 65
      ExplicitHeight = 56
      DesignSize = (
        150
        45)
      object BtnSave: TUnimButton
        Left = 25
        Top = 5
        Width = 105
        Height = 37
        Hint = ''
        Anchors = [akTop, akRight]
        Caption = #20445#23384
        IconCls = 'add'
        OnClick = BtnSaveClick
      end
    end
    object PanelR: TUnimContainerPanel
      Left = 255
      Top = 0
      Width = 65
      Height = 45
      Hint = ''
      Align = alRight
      Flex = 3
      ExplicitLeft = 0
      ExplicitHeight = 56
    end
  end
end
