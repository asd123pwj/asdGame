using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using Newtonsoft.Json;

public class UIScrollViewInfo: UIInfo{
    // private string _info_type_default { get => "UIScrollViewInfo"; }

    [JsonProperty("padding", NullValueHandling = NullValueHandling.Ignore)] 
    private RectOffset _padding;
    private RectOffset _padding_default { get => new (10, 10, 10, 10); }
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
    // int num_container = 5;
    List<UIBase> containers = new();
    List<UIBase> items = new();
    // ---------- Key ----------
    // public string _subUIKey_item { get => "Items"; }


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
        
        // var item = UIClass._set_default("UIThumbnail", "yang");
        // item.item_index = 1;
        // List<UIInfo> items = new(){
        //     item
        // };
        // _update_slots(items);

        set_grid();
        _init_container();
        _init_item();

    }

    void set_grid(){
        if (_info is UIScrollViewInfo info){
            grid.padding = info.padding;
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
            var item = _info.items[i];
            var item_ = UIClass._set_default(item.type, item);
            resize_item_to_container(item_);
            // ----- draw item
            UIBase UI = UIDraw._draw_UI(containers[item_.item_index]._self, item_.type, item_);
            items[item_.item_index] = UI;
        }
        foreach(int i in items_without_itemIndex){
            
            var item = _info.items[i];
            var item_ = UIClass._set_default(item.type, item);
            resize_item_to_container(item_);
            // ----- draw item
            int container_index = items.FindIndex(item => item == null);
            item_.item_index = container_index;
            UIBase UI = UIDraw._draw_UI(containers[item_.item_index]._self, item_.type, item_);
            items[item_.item_index] = UI;
        }
        // foreach(var item in _info.subUIs[_subUIKey_item]){
        //     var item_ = UIClass._set_default(item.type, item);
        //     resize_item_to_container(item_);
        //     // ----- draw item
        //     UIBase UI = UIDraw._draw_UI(containers[item_.item_index]._self, item_.type, item_);
        //     items.Add(UI);
        // }
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
            var container_base = expend();
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
        foreach (var info in _info.items){
            if (info.item_index == item_base._info.item_index){
                _info.items.Remove(info);
                break;
            }
        }
    }

    UIBase expend(){
        string name = "UIContainer " + (containers.Count + 1);
        UIInfo info = UIClass._set_default("UIContainer", name);
        var UI = UIDraw._draw_UI(Content, "UIContainer", info);
        return UI;
    }

}
