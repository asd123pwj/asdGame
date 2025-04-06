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
    [JsonIgnore] public Color color {
        get => _color ?? _color_default;
        set => _color = value;
    }
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
        // Text = _self.GetComponent<TextMeshProUGUI>() ?? _self.AddComponent<TextMeshProUGUI>();
        // if (_info is UIScrollTextInfo info){
        //     TMP_Text.color = info.color;
        // }
        
    }

    public override void _init_done(){
        if (_info is UIScrollTextInfo info){
            TMP_Text.color = info.color;
        }
    }

    public override void _register_receiver(){
        base._register_receiver();
        _Msg._add_receiver(_messageID, _update_text);
    }

    public void _update_text(DynamicValue text){
        _text = _text + "\n" + text.get();
        move_buttom().Forget();
    }

    async UniTaskVoid move_buttom(){
        await UniTask.Delay(10);
        ScrollRect.normalizedPosition = Vector2.zero;
    }

    // void onSubmit(string _) => _Event._action_submit(new(EventSystem.current), false);

    public override void _update_info(){
        base._update_info();
        if (_info is UIScrollTextInfo info){
        }
    }
}
