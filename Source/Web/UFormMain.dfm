object fFormMain: TfFormMain
  Left = 0
  Top = 0
  ClientHeight = 527
  ClientWidth = 320
  Caption = #20027#31383#21475
  ShowTitle = False
  CloseButton.Visible = False
  TitleButtons = <>
  PixelsPerInch = 96
  TextHeight = 13
  ScrollPosition = 0
  ScrollHeight = 0
  PlatformData = {}
  object PanelMain: TUnimContainerPanel
    Left = 0
    Top = 0
    Width = 320
    Height = 527
    Hint = ''
    Align = alClient
    AlignmentControl = uniAlignmentClient
    object Menu1: TUnimNestedList
      Left = 0
      Top = 0
      Width = 320
      Height = 527
      Hint = ''
      Align = alClient
      Items.FontData = {0100000000}
      Title = #21151#33021#28165#21333
      SourceMenu = MenuMain
    end
  end
  object MenuMain: TUniMenuItems
    Images = UniMainModule.ImageListSmall
    Left = 24
    Top = 16
    object MenuVIP1: TUniMenuItem
      Caption = 'VIP'#36710#36742
      OnClick = MenuVIP1Click
    end
  end
end
