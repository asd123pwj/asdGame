using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using Newtonsoft.Json;
using Force.DeepCloner;
using Cysharp.Threading.Tasks;

public class UIScrollViewInfo: UIInfo{
    // private string _info_type_default { get => "UIScrollViewInfo"; }

    [JsonProperty("padding", NullValueHandling = NullValueHandling.Ignore)] 
    private RectOffset _padding;
    private RectOffset _padding_default { get => new (4, 4, 4, 4); }
    [JsonIgnore] public RectOffset padding {
        get => _padding ?? _padding_default;
        set => _padding = value;
    }

    [JsonProperty("cellSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _cellSize;
    private Vector2 _cellSize_default { get => new (100, 100); }
    [JsonIgnore] public Vector2 cellSize {
        get => _cellSize ?? _cellSize_default;
        set => _cellSize = value;
    }

    [JsonProperty("spacing", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _spacing;
    private Vector2 _spacing_default { get => new (20, 20); }
    [JsonIgnore] public Vector2 spacing {
        get => _spacing ?? _spacing_default;
        set => _spacing = value;
    }
    
    [JsonProperty("constraint", NullValueHandling = NullValueHandling.Ignore)] 
    private GridLayoutGroup.Constraint? _constraint;
    private GridLayoutGroup.Constraint _constraint_default { get => GridLayoutGroup.Constraint.FixedColumnCount; }
    [JsonIgnore] public GridLayoutGroup.Constraint constraint {
        get => _constraint ?? _constraint_default;
        set => _constraint = value;
    }

    [JsonProperty("constraintCount", NullValueHandling = NullValueHandling.Ignore)] 
    private int? _constraintCount;
    private int _constraintCount_default { get => 5; }
    [JsonIgnore] public int constraintCount {
        get => _constraintCount ?? _constraintCount_default;
        set => _constraintCount = value;
    }

    [JsonProperty("maxSize", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _maxSize;
    private Vector2 _maxSize_default { get => new (-1, -1); }
    [JsonIgnore] public Vector2 maxSize {
        get => _maxSize ?? _maxSize_default;
        set => _maxSize = value;
    }

    [JsonProperty("minSize", NullValueHandling = NullValueHandling.Ignore)]
    private Vector2? _minSize;
    private Vector2 _minSize_default { get => new (64, 64); }
    [JsonIgnore] public Vector2 minSize {
        get => _minSize ?? _minSize_default;
        set => _minSize = value;
    }
    
    [JsonProperty("items", NullValueHandling = NullValueHandling.Ignore)]
    private List<UIInfo> _items; 
    [JsonIgnore] public List<UIInfo> items { get => _items; set => _items = value; }
}

public class UIScrollView: UIBase{
    // ---------- Prefab Child ----------
    GameObject Viewport;
    GameObject Content;
    GameObject Scrollbar_Horizontal;
    GameObject Scrollbar_Vertical;
    // ---------- Config ----------
    GridLayoutGroup grid;
    public new UIScrollViewInfo _info {get => (UIScrollViewInfo)base._info; set => base._info = value; }
    // RectOffset grid_padding { get { return grid.padding; } set { grid.padding = value; } }
    // Vector2 grid_cellSize { get { return grid.cellSize; } set { grid.cellSize = value; } }
    // Vector2 grid_spacing { get { return grid.spacing; } set { grid.spacing = value; } }
    // GridLayoutGroup.Constraint grid_constraint { get { return grid.constraint; } set { grid.constraint = value; } }
    // int grid_constraintCount { get { return grid.constraintCount; } set { grid.constraintCount = value; } }
    // ---------- Status ----------
    public override float _update_interval { get; set; } = 0.01f;
    List<UIBase> containers = new();
    List<UIBase> items = new();
    bool withScrollbarHorizontal = false;
    bool withScrollbarVertical = false; 
    int  withItems = -1;
    // ---------- Key ----------


    public UIScrollView(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_begin(){
        Viewport = _self.transform.Find("Viewport").gameObject;
        Content = Viewport.transform.Find("Content").gameObject;
        Scrollbar_Horizontal = _self.transform.Find("Scrollbar Horizontal").gameObject;
        Scrollbar_Vertical = _self.transform.Find("Scrollbar Vertical").gameObject;
        grid = Content.GetComponent<GridLayoutGroup>();
    }

    public override void _init_done(){
        set_grid();
        _init_container();
        _init_item();
    }

    public override void _update(){
        adaptive_resize();
    }

    void adaptive_resize(){
        // ----- resize condition----- //
        if (_self.activeSelf == false) return;
        if (withItems == items.Count
            && withScrollbarHorizontal == Scrollbar_Horizontal.activeSelf
            && withScrollbarVertical == Scrollbar_Vertical.activeSelf) return;

        // ----- resize ----- //
        Vector2 size = Vector2.zero;
        if (grid.constraint != GridLayoutGroup.Constraint.FixedColumnCount) return;
        size.x = grid.cellSize.x * grid.constraintCount 
                + grid.spacing.x * (grid.constraintCount - 1) 
                + grid.padding.left + grid.padding.right;
        size.y = grid.cellSize.y * Mathf.CeilToInt((float)items.Count / grid.constraintCount) 
                + grid.spacing.y * Mathf.CeilToInt((float)items.Count / grid.constraintCount - 1) 
                + grid.padding.top + grid.padding.bottom;
        if (Scrollbar_Horizontal.activeSelf) size.y += Scrollbar_Horizontal.GetComponent<RectTransform>().rect.height;
        if (Scrollbar_Vertical.activeSelf) size.x += Scrollbar_Vertical.GetComponent<RectTransform>().rect.width;
        size = Vector2.Max(size, _info.minSize);
        if (_info.maxSize.x != -1) size.x = Mathf.Min(size.x, _info.maxSize.x);
        if (_info.maxSize.y != -1) size.y = Mathf.Min(size.y, _info.maxSize.y);
        _rt_self.sizeDelta = size;

        // ----- update status ----- //
        withItems = items.Count;
        withScrollbarHorizontal = Scrollbar_Horizontal.activeSelf;
        withScrollbarVertical = Scrollbar_Vertical.activeSelf;
    }

    void set_grid(){
        if (_info is UIScrollViewInfo info){
            grid.padding = info.padding.DeepClone();
            grid.cellSize = info.cellSize;
            grid.spacing = info.spacing;
            grid.constraint = info.constraint;
            grid.constraintCount = info.constraintCount;
        }
    }

    bool _init_item(){
        // ----- No item
        // if (!_info.subUIs.ContainsKey(_subUIKey_item)) return true;
        if (_info.items == null) {
            _info.items = new();
            return true;
        }
        // ----- init item to container by item_index
        List<int> items_without_itemIndex = new();
        for (int i = 0; i < _info.items.Count; i++){
            if (_info.items[i].item_index == -1){
                items_without_itemIndex.Add(i);
                continue;
            }
            UIInfo item = _info.items[i];
            UIInfo item_ = UIClass._set_default(item.type, item);
            resize_item_to_container(item_);
            // ----- Mark item of right menu ----- //
            if (_attributes != null && _attributes.ContainsKey("RIGHT_MENU_OWNER")) {
                item_.attributes ??= new();
                item_.attributes["RIGHT_MENU_OWNER"] = _attributes["RIGHT_MENU_OWNER"];
            }
            // ----- draw item
            UIBase UI = UIDraw._draw_UI(containers[item_.item_index]._self, item_.type, item_);
            items[item_.item_index] = UI;
        }
        foreach(int i in items_without_itemIndex){
            
            UIInfo item = _info.items[i];
            UIInfo item_ = UIClass._set_default(item.type, item);
            resize_item_to_container(item_);
            // ----- Mark item of right menu ----- //
            if (_attributes != null && _attributes.ContainsKey("RIGHT_MENU_OWNER")) {
                item_.attributes ??= new();
                item_.attributes["RIGHT_MENU_OWNER"] = _attributes["RIGHT_MENU_OWNER"];
            }
            // ----- draw item
            int container_index = items.FindIndex(item => item == null);
            item_.item_index = container_index;
            UIBase UI = UIDraw._draw_UI(containers[item_.item_index]._self, item_.type, item_);
            items[item_.item_index] = UI;
        }
        return true;
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




    public override void _update_info(){
        base._update_info();
        if (_info is UIScrollViewInfo info){
            info.padding = grid.padding;
            info.cellSize = grid.cellSize;
            info.spacing = grid.spacing;
            info.constraint = grid.constraint;
            info.constraintCount = grid.constraintCount;
        }
    }



    UIInfo resize_item_to_container(UIInfo item){
        item.isItem = true;

        Vector2 new_size = grid.cellSize * 0.8f;
        Vector2 new_scale = new_size / item.sizeDelta;
        float maxScale = Mathf.Min(new_scale.x, new_scale.y);
        item.localScale = new Vector2(maxScale, maxScale);;
        item.anchorMin = new Vector2(0.5f, 0.5f);
        item.anchorMax = new Vector2(0.5f, 0.5f);
        item.pivot = new Vector2(0.5f, 0.5f);
        return item;
    }

    void _init_container(){
        for (int i = 0; i < _info.items.Count; i++){
            UIBase container_base = expend();
            containers.Add(container_base);
            items.Add(null);
        }
    }

    public void _add_item(UIBase item_base){
        // if (!_info.subUIs.ContainsKey(_subUIKey_item)) 
        //     _info.subUIs.Add(_subUIKey_item, new());
        _info.items.Add(item_base._info);
    }

    public void _remove_item(UIBase item_base){
        // remove item from containerUIInfos
        foreach (UIInfo info in _info.items){
            if (info.item_index == item_base._info.item_index){
                _info.items.Remove(info);
                break;
            }
        }
    }

    UIBase expend(){
        string name = "UIContainer " + (containers.Count + 1);
        UIInfo info = UIClass._set_default("UIContainer", name);
        // ----- Mark item of right menu ----- //
        if (_attributes != null && _attributes.ContainsKey("RIGHT_MENU_OWNER")) {
            info.attributes ??= new();
            info.attributes["RIGHT_MENU_OWNER"] = _attributes["RIGHT_MENU_OWNER"];
        }
        // ----- Draw ----- //
        UIBase UI = UIDraw._draw_UI(Content, "UIContainer", info);
        return UI;
    }

}
