public class MaterialSystem: BaseClass{
    // ---------- Status ---------- //
    bool all_info_initDone = false;
    // ---------- Sub Manager ---------- //
    // public ObjectManager _obj;
    // public UIPrefabManager _UIPfb;
    // public UISpriteManager _UISpr;
    public TileManager _tile;
    public MaterialManager _mat;
    public MeshManager _mesh;
    public PhysicsMaterialManager _phyMat;
    public TerrainManager _terrain;
    public SpriteMaterialPreprocessor _sprMat;
    public FontManager _font;
    public PrefabManager _pfb;
    public SpriteManager _spr;

    public override void _init(){
        // _obj = new();
        // _UIPfb = new();
        // _UISpr = new();
        _tile = new();
        _mat = new();
        _mesh = new();
        _phyMat = new();
        _terrain = new();
        _sprMat = new();
        _font = new();
        _pfb = new();
        _spr = new();
    }
    
    public bool _check_all_info_initDone(){
        if (all_info_initDone) return true;
        if (!_initDone) return false;
        // if (!_obj._check_info_initDone()) return false;
        // if (!_UIPfb._check_info_initDone()) return false;
        // if (!_UISpr._check_info_initDone()) return false;
        if (!_tile._check_info_initDone()) return false;
        if (!_mat._check_info_initDone()) return false;
        if (!_mesh._check_info_initDone()) return false;
        if (!_phyMat._check_info_initDone()) return false;
        if (!_terrain._check_info_initDone()) return false;
        if (!_sprMat._check_info_initDone()) return false;
        if (!_font._check_info_initDone()) return false;
        if (!_pfb._check_info_initDone()) return false;
        if (!_spr._check_info_initDone()) return false;
        all_info_initDone = true;
        return true;
    }


}
