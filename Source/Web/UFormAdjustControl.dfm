inherited fFormAdjustControl: TfFormAdjustControl
  Caption = #25968#25454#26657#27491
  PixelsPerInch = 96
  TextHeight = 13
  ScrollPosition = 0
  ScrollHeight = 47
  PlatformData = {}
  object PanelTool: TUnimContainerPanel
    Left = 0
    Top = 0
    Width = 320
    Height = 480
    Hint = ''
    Align = alClient
    AlignmentControl = uniAlignmentClient
    Layout = 'hbox'
    object PanelL: TUnimContainerPanel
      Left = 0
      Top = 0
      Width = 57
      Height = 480
      Hint = ''
      Align = alLeft
      Layout = 'hbox'
      LayoutAttribs.Align = 'center'
      LayoutAttribs.Pack = 'center'
      Flex = 1
      ExplicitLeft = -6
    end
    object PanelC: TUnimContainerPanel
      Left = 57
      Top = 0
      Width = 215
      Height = 480
      Hint = ''
      Align = alClient
      LayoutAttribs.Align = 'center'
      LayoutAttribs.Pack = 'center'
      Flex = 8
      DesignSize = (
        215
        480)
      object LabelStatus: TUnimLabel
        Left = 42
        Top = 30
        Width = 105
        Height = 25
        Hint = ''
        AutoSize = False
        Caption = #24403#21069':'
      end
      object BtnFresh: TUnimButton
        Left = 42
        Top = 61
        Width = 105
        Height = 37
        Hint = ''
        Anchors = [akTop, akRight]
        Caption = #21047#26032
        IconCls = 'refresh'
        LayoutConfig.Margin = '5 0 0 0'
        OnClick = BtnFreshClick
      end
      object BtnOpen: TUnimButton
        Left = 42
        Top = 173
        Width = 105
        Height = 37
        Hint = ''
        Anchors = [akTop, akRight]
        Caption = #25171#24320
        IconCls = 'settings'
        LayoutConfig.Margin = '25 0 0 0'
        OnClick = BtnOpenClick
      end
      object BtnClose: TUnimButton
        Left = 42
        Top = 216
        Width = 105
        Height = 37
        Hint = ''
        Anchors = [akTop, akRight]
        Caption = #20851#38381
        IconCls = 'delete'
        LayoutConfig.Margin = '5 0 0 0'
        OnClick = BtnCloseClick
      end
      object LabelHint: TUnimLabel
        Left = 0
        Top = 344
        Width = 215
        Height = 136
        Hint = ''
        AutoSize = False
        Caption = ''
        Align = alBottom
        LayoutConfig.Margin = '5 0 0 0'
      end
    end
    object PanelR: TUnimContainerPanel
      Left = 272
      Top = 0
      Width = 48
      Height = 480
      Hint = ''
      Align = alRight
      Flex = 1
    end
  end
end
