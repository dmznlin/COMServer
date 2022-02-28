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
    Height = 432
    Hint = ''
    Align = alClient
    EmptyText = #36755#20837' '#25110' '#31896#36148#36710#36742#21015#34920
    TabOrder = 0
    ExplicitTop = -6
  end
  object PanelB: TUnimPanel
    Left = 0
    Top = 432
    Width = 320
    Height = 48
    Hint = ''
    Align = alBottom
    AlignmentControl = uniAlignmentClient
    LayoutAttribs.Align = 'center'
    LayoutAttribs.Pack = 'center'
    ExplicitTop = 438
    object BtnSave: TUnimButton
      Left = 112
      Top = 6
      Width = 105
      Height = 37
      Hint = ''
      Caption = #20445#23384
      IconCls = 'add'
      OnClick = BtnSaveClick
    end
  end
end
