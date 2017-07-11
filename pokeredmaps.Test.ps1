Describe "mapheaders" {
    $tilesetlist = (Get-Content .\tilesetlist.txt) -split "`n"
    $dataregex = [regex]"`tdb\s(\w+)"
    $MapNameDictionary = Import-Csv "$scriptdir\mapnamedictionary.csv"

    Context "Tilesets" {
        $MapNameDictionary | ForEach-Object {
            $map = $_.file
            if ($map.Contains("unused")) { return }
            It "obtains the tileset for $map" {
                $tileset = (mapheaders $map).tileset
                if ($tileset -match "\w+") {
                    $tileset = $tilesetlist.IndexOf($tileset)
                } else  {
                    $tileset = [int]$tileset
                }
                $correctTileset = $tilesetlist.IndexOf($dataregex.Match((Get-Content .\pokered\data\mapHeaders\$map.asm)).Groups[1].Value)
                $tileset | Should Be $correctTileset
            }
        }
    }
}