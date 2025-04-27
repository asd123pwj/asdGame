using UnityEngine;
using UnityEngine.EventSystems;
using TMPro;
using Newtonsoft.Json;
using UnityEngine.UI;
using Cysharp.Threading.Tasks;

public class UIScrollTextInfo: UIInfo{
    
    [JsonProperty("textColor", NullValueHandling = NullValueHandling.Ignore)] 
    private Color? _textColor;
    private Color _textColor_default { get => Color.black; }
    [JsonIgnore] public Color textColor { get => _textColor ?? _textColor_default; set => _textColor = value; }
    
    [JsonProperty("maxSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _maxSize;
    private Vector2 _maxSize_default { get => new (640, 640); }
    [JsonIgnore] public Vector2 maxSize { get => _maxSize ?? _maxSize_default; set => _maxSize = value; }

    [JsonProperty("minSize", NullValueHandling = NullValueHandling.Ignore)]
    private Vector2? _minSize;
    private Vector2 _minSize_default { get => new (64, 64); }
    [JsonIgnore] public Vector2 minSize { get => _minSize ?? _minSize_default; set => _minSize = value; }

    [JsonProperty("text", NullValueHandling = NullValueHandling.Ignore)]
    private string _text;
    private string _text_default => "";
    [JsonIgnore] public string text { get => _text ?? _text_default; set => _text = value; }
    

    [JsonProperty("marginTop", NullValueHandling = NullValueHandling.Ignore)] 
    private int? _marginTop;
    private int _marginTop_default => 6;
    [JsonIgnore] public int marginTop { get => _marginTop ?? _marginTop_default; set => _marginTop = value; }

    [JsonProperty("marginBottom", NullValueHandling = NullValueHandling.Ignore)]
    private int? _marginBottom;
    private int _marginBottom_default => 4;
    [JsonIgnore] public int marginBottom { get => _marginBottom ?? _marginBottom_default; set => _marginBottom = value; }

    [JsonProperty("marginLeft", NullValueHandling = NullValueHandling.Ignore)]
    private int? _marginLeft;
    private int _marginLeft_default => 12;
    [JsonIgnore] public int marginLeft { get => _marginLeft ?? _marginLeft_default; set => _marginLeft = value; }

    [JsonProperty("marginRight", NullValueHandling = NullValueHandling.Ignore)]
    private int? _marginRight;
    private int _marginRight_default => 12;
    [JsonIgnore] public int marginRight { get => _marginRight ?? _marginRight_default; set => _marginRight = value; }


    [JsonProperty("fontSize", NullValueHandling = NullValueHandling.Ignore)]
    private int? _fontSize;
    private int _fontSize_default => 20;
    [JsonIgnore] public int fontSize { get => _fontSize ?? _fontSize_default; set => _fontSize = value; }
    
    [JsonProperty("font", NullValueHandling = NullValueHandling.Ignore)]
    private string _font;
    private string _font_default => "fusion_pixel_12px_zh_hans";
    [JsonIgnore] public string font { get => _font ?? _font_default; set => _font = value; }
    
    [JsonProperty("isAppend", NullValueHandling = NullValueHandling.Ignore)]
    private bool? _isAppend;
    private bool _isAppend_default => false;
    [JsonIgnore] public bool isAppend { get => _isAppend ?? _isAppend_default; set => _isAppend = value; }

    [JsonProperty("source", NullValueHandling = NullValueHandling.Ignore)]
    private string _source;
    private string _source_default => "";
    [JsonIgnore] public string source { get => _source ?? _source_default; set => _source = value; }

    [JsonProperty("scrollbarHandleBackground", NullValueHandling = NullValueHandling.Ignore)]
    private string _scrollbarHandleBackground;
    private string _scrollbarHandleBackground_default => "ui_RoundedIcon_8_Gray";
    [JsonIgnore] public string scrollbarHandleBackground { get => _scrollbarHandleBackground ?? _scrollbarHandleBackground_default; set => _scrollbarHandleBackground = value; }

    [JsonProperty("scrollbarBackground", NullValueHandling = NullValueHandling.Ignore)]
    private string _scrollbarBackground;
    private string _scrollbarBackground_default => "ui_RoundedIcon_8";
    [JsonIgnore] public string scrollbarBackground { get => _scrollbarBackground ?? _scrollbarBackground_default; set => _scrollbarBackground = value; }


}

public class UIScrollText: UIBase{
    // ---------- Public ---------- //

    // ---------- Child ---------- //
    TextMeshProUGUI TMP_Text;
    ScrollRect ScrollRect;
    GameObject Viewport;
    GameObject Content;
    GameObject Scrollbar_Horizontal;
    GameObject Scrollbar_Vertical;
    GameObject Text;
    // ---------- Status ---------- //
    public UIBase owner;
    // ---------- Config ---------- //
    public new UIScrollTextInfo _info {get => (UIScrollTextInfo)base._info; set => base._info = value; }


    public UIScrollText(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_begin(){
        init_child();
        init_owner();
    }

    public override void _init_done(){
        init_TMPText();
    }

    public override void _apply_UIShape(){
        base._apply_UIShape();
        adaptive_resize();
    }

    void init_child(){
        Viewport = _self.transform.Find("Viewport").gameObject;
        Content = Viewport.transform.Find("Content").gameObject;

        Scrollbar_Horizontal = _self.transform.Find("Scrollbar Horizontal").gameObject;
        Scrollbar_Vertical = _self.transform.Find("Scrollbar Vertical").gameObject;
        Scrollbar_Horizontal.GetComponent<Image>().sprite = _MatSys._spr._get_sprite(_info.scrollbarBackground);
        Scrollbar_Horizontal.transform.Find("Sliding Area/Handle").GetComponent<Image>().sprite = _MatSys._spr._get_sprite(_info.scrollbarHandleBackground);
        Scrollbar_Vertical.GetComponent<Image>().sprite = _MatSys._spr._get_sprite(_info.scrollbarBackground);
        Scrollbar_Vertical.transform.Find("Sliding Area/Handle").GetComponent<Image>().sprite = _MatSys._spr._get_sprite(_info.scrollbarHandleBackground);
    
        Text = Content.transform.Find("Text").gameObject;
        TMP_Text = Text.GetComponent<TextMeshProUGUI>();
        ScrollRect = _self.GetComponent<ScrollRect>();
        
    }

    void init_TMPText(){
        TMP_Text.font = _MatSys._font._get_fontTMP(_info.font);
        TMP_Text.fontSize = _info.fontSize;
        TMP_Text.color = _info.textColor;
        TMP_Text.margin = new(_info.marginLeft, _info.marginTop, _info.marginRight, _info.marginBottom);
        get_text();
    }

    void init_owner(){
        if (!_info.messageID.StartsWith("OWNER_")) return;
        int owner_id = int.Parse(_info.messageID.Split('_')[1]);
        owner = _UISys._UIMonitor._get_UI(owner_id);
    }

    public virtual void get_text(){
        TMP_Text.text = _info.source == "" ? _info.text : owner._info.attributes[_info.source].get<string>();
    }

    void adaptive_resize(){
        _rt_self.sizeDelta = new Vector2(
            Mathf.Clamp(TMP_Text.preferredWidth, _info.minSize.x, _info.maxSize.x),
            Mathf.Clamp(TMP_Text.preferredHeight, _info.minSize.y, _info.maxSize.y)
        );
    }

    public override void _register_receiver(){
        base._register_receiver();
        _Msg._add_receiver(_info.messageID, _update_text);
    }

    public async UniTask _update_text(DynamicValue text){
        update_text(text.get<string>());
        adaptive_resize();
        sync_with_source(text);
        if (_info.isAppend) move_to_bottom().Forget();
    }

    void update_text(string text){
        if (_info.isAppend) TMP_Text.text += "\n" + text;
        else TMP_Text.text = text;
    }

    public virtual void sync_with_source(DynamicValue value){
        if (_info.source == "") return;
        owner._info.attributes[_info.source] = value;
        Debug.Log(owner._info.attributes[_info.source]);
    }

    async UniTaskVoid move_to_bottom(){
        await UniTask.Delay(10);
        ScrollRect.normalizedPosition = Vector2.zero;
    }
}
