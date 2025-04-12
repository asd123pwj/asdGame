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
    
    [JsonProperty("isAppend", NullValueHandling = NullValueHandling.Ignore)]
    private bool? _isAppend;
    private bool _isAppend_default => false;
    [JsonIgnore] public bool isAppend { get => _isAppend ?? _isAppend_default; set => _isAppend = value; }

    [JsonProperty("source", NullValueHandling = NullValueHandling.Ignore)]
    private string _source;
    private string _source_default => "";
    [JsonIgnore] public string source { get => _source ?? _source_default; set => _source = value; }
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
    UIBase owner;
    // ---------- Config ---------- //
    public new UIScrollTextInfo _info {get => (UIScrollTextInfo)base._info; set => base._info = value; }


    public UIScrollText(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_begin(){
        Viewport = _self.transform.Find("Viewport").gameObject;
        Content = Viewport.transform.Find("Content").gameObject;
        Scrollbar_Horizontal = _self.transform.Find("Scrollbar Horizontal").gameObject;
        Scrollbar_Vertical = _self.transform.Find("Scrollbar Vertical").gameObject;
        Text = Content.transform.Find("Text").gameObject;
        TMP_Text = Text.GetComponent<TextMeshProUGUI>();
        ScrollRect = _self.GetComponent<ScrollRect>();
        init_owner();
        init_TMPText();
    }

    public override void _init_done(){
    }

    public override void _apply_UIShape(){
        base._apply_UIShape();
        adaptive_resize();
    }

    void init_TMPText(){
        TMP_Text.font = _MatSys._font._get_fontTMP("fusion_pixel");
        if (_info.source == "") {
            TMP_Text.text = _info.text;
        }
        else{
            TMP_Text.text = owner._info.attributes[_info.source].get<string>();
        }
        TMP_Text.color = _info.textColor;
    }

    void init_owner(){
        if (!_info.messageID.StartsWith("OWNER_")) return;
        int owner_id = int.Parse(_info.messageID.Split('_')[1]);
        owner = _UISys._UIMonitor._get_UI(owner_id);
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

    public void _update_text(DynamicValue text){
        update_text(text.get<string>());
        adaptive_resize();
        sync_with_source(text);
        if (_info.isAppend) move_to_bottom().Forget();
    }

    void update_text(string text){
        if (_info.isAppend) TMP_Text.text += "\n" + text;
        else TMP_Text.text = text;
    }

    void sync_with_source(DynamicValue value){
        if (_info.source == "") return;
        owner._info.attributes[_info.source] = value;
        Debug.Log(owner._info.attributes[_info.source]);
    }

    async UniTaskVoid move_to_bottom(){
        await UniTask.Delay(10);
        ScrollRect.normalizedPosition = Vector2.zero;
    }
}
