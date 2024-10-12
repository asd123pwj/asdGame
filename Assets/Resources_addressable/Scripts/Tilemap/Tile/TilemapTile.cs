public class TilemapTile{
    public TileP3D P3D;
    public DecorationBase decoration;

    public string tile;

    public void _set_tile(string tile){
        this.tile = tile;
    }
    public string _get_tile() => tile;
}