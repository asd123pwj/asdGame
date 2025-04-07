using UnityEngine;
using UnityEngine.EventSystems;
using TMPro;
using Newtonsoft.Json;
using UnityEngine.UI;
using Cysharp.Threading.Tasks;

public class UIScrollTextInfo: UIInfo{
    
    [JsonProperty("color", NullValueHandling = NullValueHandling.Ignore)] 
    private Color? _color;
    private Color _color_default { get => Color.black; }
    [JsonIgnore] public Color color { get => _color ?? _color_default; set => _color = value; }
    
    [JsonProperty("maxSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _maxSize;
    private Vector2 _maxSize_default { get => new (640, 640); }
    [JsonIgnore] public Vector2 maxSize { get => _maxSize ?? _maxSize_default; set => _maxSize = value; }

    [JsonProperty("minSize", NullValueHandling = NullValueHandling.Ignore)]
    private Vector2? _minSize;
    private Vector2 _minSize_default { get => new (64, 64); }
    [JsonIgnore] public Vector2 minSize { get => _minSize ?? _minSize_default; set => _minSize = value; }
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
    public string _text { get => TMP_Text.text; set => TMP_Text.text = value; }
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
        TMP_Text.font = _MatSys._font._get_fontTMP("fusion_pixel");
        ScrollRect = _self.GetComponent<ScrollRect>();
        
    }

    public override void _init_done(){
        TMP_Text.color = _info.color;
        adaptive_resize();
    }

    void adaptive_resize(){
        float text_width = Mathf.Max(_info.minSize.x, TMP_Text.preferredWidth);
        float text_height = Mathf.Max(_info.minSize.y, TMP_Text.preferredHeight);
        text_width = Mathf.Min(_info.maxSize.x, text_width);
        text_height = Mathf.Min(_info.maxSize.y, text_height);
        _rt_self.sizeDelta = new Vector2(text_width, text_height);
    }

    public override void _register_receiver(){
        base._register_receiver();
        _Msg._add_receiver(_info.messageID, _update_text);
    }

    public void _update_text(DynamicValue text){
        _text = _text + "\n" + text.get();
        adaptive_resize();
        move_to_bottom().Forget();
    }

    async UniTaskVoid move_to_bottom(){
        await UniTask.Delay(10);
        ScrollRect.normalizedPosition = Vector2.zero;
    }
}
