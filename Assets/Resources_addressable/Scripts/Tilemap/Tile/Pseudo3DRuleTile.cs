using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

[CreateAssetMenu(menuName = "2D/Tiles/Pseudo3D Rule Tile")]
public class Pseudo3DRuleTile : RuleTile<Pseudo3DRuleTile.Neighbor> {
    public bool isTransparent; 

    public class Neighbor : RuleTile.TilingRule.Neighbor {
        public const int Null = 3;
        public const int NotNull = 4;
        public const int Transparent = 5;
        public const int NotTransparent = 6;
        public const int TransparentOrNull = 7;
        public const int TransparentOrNotNull = 8;
    }

    public override bool RuleMatch(int neighbor, TileBase tile) {
        switch (neighbor) {
            case Neighbor.Null: return tile == null;
            case Neighbor.NotNull: return tile != null;
            case Neighbor.Transparent: return tile is Pseudo3DRuleTile rule_tile && rule_tile.isTransparent;
            case Neighbor.NotTransparent: return tile is Pseudo3DRuleTile rule_tile_2 && !rule_tile_2.isTransparent;
            case Neighbor.TransparentOrNull: return tile == null || tile is Pseudo3DRuleTile rule_tile3 && rule_tile3.isTransparent;
            case Neighbor.TransparentOrNotNull: return tile != null || tile is Pseudo3DRuleTile rule_tile4 && rule_tile4.isTransparent;
        }
        return base.RuleMatch(neighbor, tile);
    }
}