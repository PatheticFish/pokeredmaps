Describe "mapheaders" {
    $tilesetlist = (Get-Content .\tilesetlist.txt) -split "`n"
    $dataregex = [regex]"`tdb\s(\w+)"
    $MapNameDictionary = Import-Csv "$scriptdir\mapnamedictionary.csv"
    $MapDimensionsTable = Import-Csv "$scriptdir\mapdimensions.csv"

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

    Context "Dimensions" {
        $MapNameDictionary | ForEach-Object {
            $map = $_.CONSTANT
            if ($map.Contains("UNUSED")) { return }
            It "obtains the correct dimensions for $map" {
                $headerobject = mapheaders $map
                $entry = $MapDimensionsTable | Where {$_.MAP -eq $map}

                $headerobject.width | Should Be $entry.WIDTH
                $headerobject.height | Should Be $entry.HEIGHT
            }
        }
    }

    Context "Write" {
        It "writes valid tilesets to the header file" {
            $headerobject = mapheaders "pallettown"
            mapheaders "pallettown" -tileset "CEMETERY"
            (mapheaders "pallettown").tileset | Should Be "CEMETERY"
            mapheaders "pallettown" -tileset $headerobject.tileset
            (mapheaders "pallettown").tileset | Should Be $headerobject.tileset
        }

        It "writes valid map dimensions" {
            $headerobject = mapheaders "pallettown"
            mapheaders "pallettown" -dimensions @(1,2)
            (mapheaders "pallettown") | Should BeExactly @{width = 1; height = 2; tileset = "OVERWORLD"}
            mapheaders "pallettown" -dimensions @($headerobject.width,$headerobject.height)
            (mapheaders "pallettown") | Should BeExactly $headerobject
        }

        It "ignores invalid dimensions" {
            {mapheaders "pallettown" -dimensions @(-1,1)}  | Should Throw
            {mapheaders "pallettown" -dimensions @("s",1)} | Should Throw
            {mapheaders "pallettown" -dimensions @(1,-1)}  | Should Throw
            {mapheaders "pallettown" -dimensions @(1,"s")} | Should Throw
        }
    }
}