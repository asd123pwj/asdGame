using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using Newtonsoft.Json;
// using Force.DeepCloner;
using Cysharp.Threading.Tasks;
using System.Linq;

public class UIScrollViewInfo: UIInfo{
    // private string _info_type_default { get => "UIScrollViewInfo"; }

    // [JsonProperty("padding", NullValueHandling = NullValueHandling.Ignore)] 
    // private RectOffset _padding; 
    // private RectOffset _padding_default { get => new (4, 4, 4, 4); }
    // [JsonIgnore] public RectOffset padding {
    //     get => _padding ?? _padding_default;
    //     set => _padding = value;
    // }
    
    [JsonProperty("paddingTop", NullValueHandling = NullValueHandling.Ignore)] 
    private int? _paddingTop;
    private int _paddingTop_default => 4;
    [JsonIgnore] public int paddingTop { get => _paddingTop ?? _paddingTop_default; set => _paddingTop = value; }

    [JsonProperty("paddingBottom", NullValueHandling = NullValueHandling.Ignore)]
    private int? _paddingBottom;
    private int _paddingBottom_default => 4;
    [JsonIgnore] public int paddingBottom { get => _paddingBottom ?? _paddingBottom_default; set => _paddingBottom = value; }

    [JsonProperty("paddingLeft", NullValueHandling = NullValueHandling.Ignore)]
    private int? _paddingLeft;
    private int _paddingLeft_default => 4;
    [JsonIgnore] public int paddingLeft { get => _paddingLeft ?? _paddingLeft_default; set => _paddingLeft = value; }

    [JsonProperty("paddingRight", NullValueHandling = NullValueHandling.Ignore)]
    private int? _paddingRight;
    private int _paddingRight_default => 4;
    [JsonIgnore] public int paddingRight { get => _paddingRight ?? _paddingRight_default; set => _paddingRight = value; }


    // [JsonProperty("cellSize", NullValueHandling = NullValueHandling.Ignore)] 
    // private Vector2? _cellSize;
    // private Vector2 _cellSize_default { get => new (64, 64); }
    // [JsonIgnore] public Vector2 cellSize { get => _cellSize ?? _cellSize_default; set => _cellSize = value; }

    [JsonProperty("spacing", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _spacing;
    private Vector2 _spacing_default { get => new (16, 16); }
    [JsonIgnore] public Vector2 spacing { get => _spacing ?? _spacing_default; set => _spacing = value; }
    
    // [JsonProperty("constraintType", NullValueHandling = NullValueHandling.Ignore)] 
    // private GridLayoutGroup.Constraint? _constraintType;
    // private GridLayoutGroup.Constraint _constraintType_default { get => GridLayoutGroup.Constraint.FixedColumnCount; }
    // [JsonIgnore] public GridLayoutGroup.Constraint constraintType { get => _constraintType ?? _constraintType_default; set => _constraintType = value; }

    // [JsonProperty("constraintCount", NullValueHandling = NullValueHandling.Ignore)] 
    // private int? _constraintCount;
    // private int _constraintCount_default { get => 5; }
    // [JsonIgnore] public int constraintCount { get => _constraintCount ?? _constraintCount_default; set => _constraintCount = value; }

    [JsonProperty("maxSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _maxSize;
    private Vector2 _maxSize_default { get => new (640, 640); }
    [JsonIgnore] public Vector2 maxSize { get => _maxSize ?? _maxSize_default; set => _maxSize = value; }

    [JsonProperty("minSize", NullValueHandling = NullValueHandling.Ignore)]
    private Vector2? _minSize;
    private Vector2 _minSize_default { get => new (64, 64); }
    [JsonIgnore] public Vector2 minSize { get => _minSize ?? _minSize_default; set => _minSize = value; }
    
    [JsonProperty("items", NullValueHandling = NullValueHandling.Ignore)]
    private List<UIInfo> _items; 
    [JsonIgnore] public List<UIInfo> items { get => _items; set => _items = value; }

    
    [JsonProperty("scrollbarHandleBackground", NullValueHandling = NullValueHandling.Ignore)]
    private string _scrollbarHandleBackground;
    private string _scrollbarHandleBackground_default => "ui_RoundedIcon_8_Gray";
    [JsonIgnore] public string scrollbarHandleBackground { get => _scrollbarHandleBackground ?? _scrollbarHandleBackground_default; set => _scrollbarHandleBackground = value; }

    [JsonProperty("scrollbarBackground", NullValueHandling = NullValueHandling.Ignore)]
    private string _scrollbarBackground;
    private string _scrollbarBackground_default => "ui_RoundedIcon_8";
    [JsonIgnore] public string scrollbarBackground { get => _scrollbarBackground ?? _scrollbarBackground_default; set => _scrollbarBackground = value; }

}

public class UIScrollView: UIBase{
    // ---------- Prefab Child ----------
    GameObject Viewport;
    GameObject Content;
    GameObject Scrollbar_Horizontal;
    GameObject Scrollbar_Vertical;
    RectTransform content_rt;
    // ---------- Config ----------
    // GridLayoutGroup grid;
    public new UIScrollViewInfo _info {get => (UIScrollViewInfo)base._info; set => base._info = value; }
    // ---------- Status ----------
    // public override float _update_interval { get; set; } = 0.1f;
    // int resize_pass_count = 0;
    // List<UIBase> containers = new();
    List<UIBase> items = new();
    Dictionary<UIBase, UIInfo> base2info = new();
    // bool withScrollbarHorizontal = false;
    // bool withScrollbarVertical = false; 
    // int  withItems = -1;

    // float Scrollbar_Horizontal_height = 20;
    float Scrollbar_Vertical_width = 20;
    // ---------- Key ----------


    public UIScrollView(GameObject parent, UIInfo info): base(parent, info){
        _update_interval = 0.2f;
    }

    public override void _init_begin(){
        _init_Child();
    }

    public override void _init_done(){
        // set_grid();
        // _init_container();
        _init_item();
        // place_items().Forget();
    }

    public override void _apply_UIShape(){
        base._apply_UIShape();
        place_items().Forget();
    }

    public override void _update(){
        place_items().Forget();
    }

    void _init_Child(){
        Viewport = _self.transform.Find("Viewport").gameObject;
        Content = Viewport.transform.Find("Content").gameObject;

        Scrollbar_Horizontal = _self.transform.Find("Scrollbar Horizontal").gameObject;
        Scrollbar_Vertical = _self.transform.Find("Scrollbar Vertical").gameObject;
        Scrollbar_Horizontal.GetComponent<Image>().sprite = _MatSys._spr._get_sprite(_info.scrollbarBackground);
        Scrollbar_Horizontal.transform.Find("Sliding Area/Handle").GetComponent<Image>().sprite = _MatSys._spr._get_sprite(_info.scrollbarHandleBackground);
        Scrollbar_Vertical.GetComponent<Image>().sprite = _MatSys._spr._get_sprite(_info.scrollbarBackground);
        Scrollbar_Vertical.transform.Find("Sliding Area/Handle").GetComponent<Image>().sprite = _MatSys._spr._get_sprite(_info.scrollbarHandleBackground);

        // grid = Content.GetComponent<GridLayoutGroup>();
        content_rt = Content.GetComponent<RectTransform>();
    }

    bool _init_item(){
        // ----- No item
        if (_info.items == null) {
            _info.items = new();
            return true;
        }
        // ---------- init item to container by item_index ---------- //
        order_items();
        for (int i = 0; i < _info.items.Count; i++){
            UIInfo item = _info.items[i];
            UIInfo item_ = UIClass._set_default(item.class_type, item);
            _append_and_draw_item(item_);
        }
        place_items().Forget();
        return true;
    }

    void order_items(){
        // ----- give item index ----- //
        HashSet<int> usedIndices = new();
        foreach (var item in _info.items){
            if (item.item_index != -1) usedIndices.Add(item.item_index);
        }
        int nextIndex = 0;
        foreach (var item in _info.items){
            if (item.item_index == -1){
                while (usedIndices.Contains(nextIndex)) nextIndex++;
                item.item_index = nextIndex;
                usedIndices.Add(nextIndex);
                nextIndex++;
            }
        }
        // ----- order items ----- //
        _info.items = _info.items.OrderBy(item => item.item_index).ToList();
    }

    public void _append_item(UIBase item_base, bool needPlace=false){
        // if (!_info.subUIs.ContainsKey(_subUIKey_item)) 
        //     _info.subUIs.Add(_subUIKey_item, new());
        _info.items.Add(item_base._info);
        items.Add(item_base);
        base2info.Add(item_base, item_base._info);
        if (needPlace) place_items().Forget();
    }
    public void _append_and_draw_item(UIInfo item, bool needPlace=false){
        // resize_item_to_container(item_);
        // ----- Mark item of right menu ----- //
        if (_info.attributes != null && _info.attributes.ContainsKey("OWNER")) {
            item.attributes ??= new();
            item.attributes["OWNER"] = _info.attributes["OWNER"];
        }
        // ----- draw item
        // UIBase UI = UIDraw._draw_UI(containers[item_.item_index]._self, item_.type, item_);
        UIBase UI = UIDraw._draw_UI(Content, item.class_type, item);
        items.Add(UI);
        base2info.Add(UI, item);
        if (needPlace) place_items().Forget();
    }

    async UniTaskVoid place_items(){
        // ---------- Init ---------- //
        // ----- original position ----- //
        float x_ori = _info.paddingLeft;
        float y_ori = _info.paddingTop;
        // ----- current item position ----- //
        float x_current = x_ori;
        float y_current = y_ori;
        // ----- allowed width ----- //
        // float contentWidth = _info.maxSize.x - _info.paddingLeft - _info.paddingRight - Scrollbar_Vertical_width;
        // ----- boundery size ----- //
        float h_rowMax = 0;
        float w_max = 0;

        // ---------- place items ---------- //
        for (int i = 0; i < items.Count; i++){
            // ----- Get Item ----- //
            UIBase item = items[i];
            while (item._rt_self == null) { if (_isDestroyed) return; await UniTask.Delay(10); }
            // ----- Place in this row ----- //
            if (x_current + item._rt_self.sizeDelta.x <= _info.maxSize.x - _info.paddingRight){
                item._rt_self.anchoredPosition = new Vector2(x_current, -y_current);
            }
            // ----- Place in next row ----- //
            else{
                // ----- Update Status ----- //
                w_max = Mathf.Max(w_max, x_current - _info.spacing.x);
                // ----- Place ----- //
                x_current = x_ori; 
                y_current += h_rowMax + _info.spacing.y; 
                item._rt_self.anchoredPosition = new Vector2(x_current, -y_current);
                // ----- Update Status ----- //
                h_rowMax = 0;
            }
            // ----- Update Status ----- //
            h_rowMax = Mathf.Max(h_rowMax, item._rt_self.sizeDelta.y);
            x_current += item._rt_self.sizeDelta.x + _info.spacing.x;
        }
        // ----- Update Status ----- //
        w_max = Mathf.Max(w_max, x_current - _info.spacing.x);

        // ----- Update Content Size ----- //
        float h_sum = y_current + _info.paddingBottom + h_rowMax;
        float w_sum = w_max + _info.paddingRight;
        content_rt.sizeDelta = new (content_rt.sizeDelta.x, h_sum);
        
        // ----- ScrollBar enabling, add its width ----- //
        if (h_sum > _info.maxSize.y) w_sum += Scrollbar_Vertical_width;

        // ----- Update ScrollView Size ----- //
        _rt_self.sizeDelta = new (
            Mathf.Clamp(w_sum, _info.minSize.x, _info.maxSize.x), 
            Mathf.Clamp(h_sum, _info.minSize.y, _info.maxSize.y)
        );
    }

    public void _update_slots(List<UIInfo> items){
        for(int i = 0; i < items.Count; i++){
            items[i].background_key = items[i].name;
        }
        _info.items = items;
    }

    public void _empty(){
        foreach(var item in items){
            item._destroy();
        }
    }




    // public override void _update_info(){
    //     base._update_info();
        // _info.paddingLeft = grid.padding.left;
        // _info.paddingRight = grid.padding.right;
        // _info.paddingTop = grid.padding.top;
        // _info.paddingBottom = grid.padding.bottom;
        // _info.cellSize = grid.cellSize;
        // _info.spacing = grid.spacing;
        // _info.constraintType = grid.constraint;
        // _info.constraintCount = grid.constraintCount;
    // }



    // UIInfo resize_item_to_container(UIInfo item){
    //     item.isItem = true;

    //     Vector2 new_size = _info.cellSize * 0.8f;
    //     Vector2 new_scale = new_size / item.sizeDelta;
    //     float maxScale = Mathf.Min(new_scale.x, new_scale.y);
    //     item.localScale = new Vector2(maxScale, maxScale);;
    //     item.anchorMin = new Vector2(0.5f, 0.5f);
    //     item.anchorMax = new Vector2(0.5f, 0.5f);
    //     item.pivot = new Vector2(0.5f, 0.5f);
    //     return item;
    // }

    // void _init_container(){
    //     for (int i = 0; i < _info.items.Count; i++){
    //         // UIBase container_base = expend();
    //         // containers.Add(container_base);
    //         items.Add(null);
    //     }
    // }


    public void _remove_item(UIBase item_base){
        // remove item from containerUIInfos
        _info.items.Remove(base2info[item_base]);
        // foreach (UIInfo info in _info.items){
        //     if (info.item_index == item_base._info.item_index){
        //         _info.items.Remove(info);
        //         break;
        //     }
        // }
    }

    // UIBase expend(){
    //     string name = "UIContainer " + (containers.Count + 1);
    //     UIInfo info = UIClass._set_default("UIContainer", name);
    //     // ----- Mark item of right menu ----- //
    //     if (_info.attributes != null && _info.attributes.ContainsKey("OWNER")) {
    //         info.attributes ??= new();
    //         info.attributes["OWNER"] = _info.attributes["OWNER"];
    //     }
    //     // ----- Draw ----- //
    //     UIBase UI = UIDraw._draw_UI(Content, "UIContainer", info);
    //     return UI;
    // }

}
