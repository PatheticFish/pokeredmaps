#.SYNOPSIS
# A set of command-line tools for dealing with Pokemon Red Disassembly maps.
#
#.DESCRIPTION
# map [mapname] [-basepath path]
#   Summarizes information for a given map
#   Optionally sets the root directory for the disassembly repository.
#   If no map is specified, a (plaintext) list of map names is returned.
#
# mapheaders mapname [-tileset TILESET] [-dimensions (X,Y)]
#   Reads(/writes) tileset and(/or) map size (in blocks) for given map.
#
# mapconnections mapname
#   Reads(/writes) overworld map connections for the given map.
#   Returns a compass object of dictionary of connection information (or null)
#
# mapdata mapname [data]
#   Reads(/writes) map block data.
#   Converts between the binary .blk format and a *TEXT* grid of int tile values.  
#
# mapnamedictionary.csv
#   A list of the various formats the map names appear in:
#   As constants (in data), as ASM pointers, and as filenames.
#
#.LINK
# Github: https://github.com/PatheticFish/pokeredmaps
#
#.LINK
# map
#.LINK
# mapheaders
#.LINK
# mapconnections
#
#.LINK
# Pokemon Red Disassembly: https://github.com/pret/pokered
#
#.NOTES
# At this time, only the commands described here work, and only in reading.
# No writing of values is supported yet.
# Additionally, various commands to be used by the map summary do not exist,
#   so this summary is only partial.
#

$basepath = $PWD.Path.substring(0,$PWD.Path.LastIndexOf("\pokered")+8)
$scriptdir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$MapNameDictionary = Import-Csv "$scriptdir\mapnamedictionary.csv"
Set-Variable POKERED_TILESET -option Constant -value 1
Set-Variable POKERED_DIMENSIONS -option Constant -value 2
Set-Variable POKERED_DEFS -option Constant -value 3
Set-Variable POKERED_CONNECTIONS -option Constant -value 4
Set-Variable POKERED_OBJECTS -option Constant -value 5
Set-Variable POKERED_BORDER -option Constant -value 1
Set-Variable POKERED_WARPS -option Constant -value 2
Set-Variable POKERED_SIGNS -option Constant -value 3
Set-Variable POKERED_SPRITEOBJECTS -option Constant -value 4

#.SYNOPSIS
# Summarizes in human-readable format a Pokemon map's features.
#
#.DESCRIPTION
# Returns a formatted string of useful properties of a Pokemon Red Disassembly map.
#
# If no map name is specified, a list of valid map names will be returned.
#
#.PARAMETER basepath
# Sets the root directory of the Pokemon Red disassembly
#
#.EXAMPLE
# map route1 -basepath E:\stuff\pokered-master
#
# Route1: 10x18 blocks (20x36)
# Tileset: OVERWORLD, 3 NPCs. Wild Pokemon: True
# Music: Music_Route1
#  10, 77, 82, 82, 79, 49, 80, 82, 82, 78,
#  10, 77, 10, 10, 10, 49, 10, 10,116, 78,
#  10, 77,  7,  7, 66, 26, 26, 49, 49, 78,
#  10,110,116,116,110, 11, 11, 11, 11,109,
#  10,110,  7,  7, 66, 11, 11, 11, 11,109,
#  10,110, 10,116,116, 10, 49, 49, 49,109,
#  10,110,111,  7,  7,111, 28, 11, 11,109,
#  10, 77, 10, 10,116,116, 49, 11, 11, 78,
#  10, 77, 10, 49, 49, 49, 49,116,116, 78,
#  10, 77, 47, 26, 47,  7,  7,  7,  7, 78,
#  10, 77, 10, 49, 49, 49, 49, 49, 49, 78,
#  10, 77,111,111,111,111, 11, 11, 26, 78,
#  10, 77, 10, 10,116,116, 11, 11, 49, 78,
#  10, 77, 26, 49,  8, 26, 26, 26, 26, 78,
#  10,110, 10, 11, 11, 49, 10, 11, 11,109,
#  10,110, 11, 11,116, 49, 11, 11,116,109,
#  10,110, 81, 81, 99, 11, 98, 81, 81,109,
#  10,110, 10, 10, 77, 11, 78, 10, 10,109
# Exits:
# NORTH : VIRIDIAN_CITY
# SOUTH : PALLET_TOWN
#
#.OUTPUTS
# System.String 
#
#.NOTES
# The alias Get-MapSummary is available for more idiomatic usage.
#
function map {
    param([Parameter(Mandatory=$False,Position=0)][String]$MapName,
          [Alias("b","p","path")][Parameter(Mandatory=$False)][String]$basepath = $Global:basepath)
    [String]$return = ""
    if (-not $MapName) {
        if (-not $MapNameDictionary) {
    #        Create-MapDict
        }
        $return += "Known Maps:`n"
        $MapNameDictionary | ForEach-Object {$return += $_.Pointer+"`n"}
        return $return
    }
    if ($basepath) {
        $Global:basepath = Convert-Path ($basepath -replace "[`/\\]`$","")
    }
    if ($MapNameDictionary -imatch $MapName -xor $true) {
        throw "Unknown map `"$MapName`""
    }

    $MapNames = ($MapNameDictionary -imatch $Mapname)[0]

    #Summarize data for map $MapName
    [Hashtable]$headers = mapheaders $MapNames.CONSTANT
    $objects = mapobjects $MapNames.CONSTANT
    [String]$music = mapmusic $MapNames.CONSTANT
    [Object]$connections = mapconnections $MapNames.file
    [Boolean]$wildmon = mapencounters $MapNames.CONSTANT
    [String]$mapdata = mapdata $MapNames.file -Width $headers.width

    $return += $MapNames.Pointer+": "
    $return += ""+$headers.width+"x"+$headers.height+" blocks ("
    $return += ""+($headers.width*2)+"x"+($headers.height*2)+")`n"
    $return += "Tileset "+$headers.tileset+", "+$objects.objects.length+" NPCs. "
    $return += "Wild Pokemon: $wildmon`n"
    $return += "Music: $music`n"
    $return += "$mapdata`n"
    $return += "Exits: `n"
    # Any non-null connections? 
    if ((($connections.PSObject.Properties | Where {$_.Name -eq "Values"}).Value | Where {$_ -ne $null}).count -gt 0) {
        # List them by the connected map name
        $connections.Keys | Where {$connections.Item($_) -ne $null} | ForEach-Object {
                $return += $_.toUpper().PadRight(5," ")+" : "+$connections.Item($_).connectedmap+"`n"
        }
    } else {
        $return += "None"
    }

    return $return
} Set-Alias Get-MapSummary map

#.SYNOPSIS
# Gets map header information not handled by other commands.
#
#.DESCRIPTION
# Gets map height, width, and tileset as listed in the map header file.
# The height and width are obtained from map_constants.asm
#
# Other properties in the header file are not handled by this command.
# Either the disassembly only lists pointers that involve separate file
#   handling anyway or (in the case of connections), the result is too
#   complicated for exposing through this command.
#
# Sets the tileset or dimensions, if either parameter is used.
#
#.EXAMPLE
# mapheaders route1
# 
# Name                           Value    
# ----                           -----    
# tileset                        OVERWORLD
# width                          10       
# height                         18       
#
#.EXAMPLE
# mapheaders route1 -d @(5,14)
#
# TODO
#
#.NOTES
# To view the list of tileset constants, run Get-Tilesets
#
# The aliases Get-MapHeaders and Set-MapHeaders are available for
# more idiomatic usage.
#
function mapheaders {
    param([Parameter(Mandatory=$True,Position=0)][String]$MapName,
          [Alias("t")][Parameter(Mandatory=$False)][String]$tileset,
          [Alias("d")][Parameter(Mandatory=$False)][Int[]]$dimensions)
    $MapNames = ($MapNameDictionary -imatch $MapName)[0]
    $dim = Get-MapDimensions $MapNames.CONSTANT
    return @{tileset = Get-MapTileset $MapNames.file;width=$dim.x -as [int];height=$dim.y -as [int]}
} Set-Alias Get-MapHeaders mapheaders ; Set-Alias Set-MapHeaders mapheaders


#.SYNOPSIS
# Gets map connection information from the map header file.
#
#.OUTPUT
# Dictionary of dictionaries
# {
#   north : { 
#             currentmap        : String MAP
#             connectedmap      : String MAP
#             connectionxoffset : Int
#             connectionoffset  : Int
#             connectedblocks   : String Pointer
#             addthree          : Boolean, may be omitted if false.
#           }
#   south : { ... }
#   east  : { ... }
#   west  : { ... }
# }
#
#.EXAMPLE
# mapconnections saffroncity
#
# Name                           Value                                                    
# ----                           -----                                                    
# north                          @{currentmap=SAFFRON_CITY; connectedmap=ROUTE_5; conne...
# south                          @{currentmap=SAFFRON_CITY; connectedmap=ROUTE_6; conne...
# west                           @{currentmap=SAFFRON_CITY; connectedmap=ROUTE_7; conne...
# east                           @{currentmap=SAFFRON_CITY; connectedmap=ROUTE_8; conne...
#
#.NOTES
# The alias Set-MapConnections is available for more idiomatic usage.
# At the time of writing, Get-MapConnections refers to a helper function.
#
function mapconnections {
    param([Parameter(Mandatory=$True,Position=0)][String]$MapName,
          [Alias("d")][Parameter(Mandatory=$False)][String]$directions)
    $MapNames = ($MapNameDictionary -imatch $MapName)[0]
    return Get-MapConnections $MapNames.file
} Set-Alias Set-MapConnections mapconnections

#
function mapobjects {
    param([Parameter(Mandatory=$True,Position=0)][String]$MapName,
          [Alias("b")][Parameter(Mandatory=$False)][Int]$border,
          [Alias("w")][Parameter(Mandatory=$False)][Object[]]$warps,
          [Alias("s")][Parameter(Mandatory=$False)][Object[]]$signs,
          [Alias("o")][Parameter(Mandatory=$False)][Object[]]$objects)
}

function mapdata {
    param([Parameter(Mandatory=$True,Position=0)][String]$MapName,
          [Alias("d")][Parameter(Mandatory=$False)][String]$width = (mapheaders $MapName).width)
    $MapName = ($MapNameDictionary -imatch $MapName)[0].file
    return (Get-Content "$basepath/maps/$MapName.blk") -join "`n" | Convert-MapBytesToText -Width $width
}
#Helper function for dealing with ASM data, strips comments and splits data statements
#Return one data line... maybe make this optional.
function Get-ASMDataLine {
    param([Parameter(Mandatory=$True,Position=0)][String]$file,
        [Parameter(Mandatory=$True,Position=1)][Int]$index)
    return ((Get-Content "$file") -replace ";.*$", "" -join "`n" -split "db|dw")[$index]
}

function Get-MapTileset {
    param([Parameter(Mandatory=$True,Position=0)][String]$MapName)
    if ((Get-ASMDataLine "$basepath/data/mapHeaders/$MapName.asm" $POKERED_TILESET) -match '(\w+)') {
        return $Matches[0]
    }
    return "Unknown"
}
function Get-MapDimensions {
    param([Parameter(Mandatory=$True,Position=0)][String]$MapName)
    $mc = (((Get-Content "$basepath/constants/map_constants.asm") -join "`n").Substring(68)  -replace ";.*`n","" -split "mapconst ") -match "$MapName,"
    return $mc | ConvertFrom-Csv -Header map,y,x
}
#comment this
function Get-MapConnections {
    param([Parameter(Mandatory=$True,Position=0)][String]$MapName)
    $connection = Get-ASMDataLine "$basepath/data/mapHeaders/$MapName.asm" $POKERED_CONNECTIONS
    if ($connection.Trim().Equals('$00')) {
        return Create-MapConnectionsTable
    }
    $connection = $connection -split "`n"
    $directions = ([regex]::Matches($connection[0], "\w+"))[0..3]
    
    for ($i = 0; $i -lt $directions.length; $i++) {
        $ConnectionObject = ConvertFrom-Csv -InputObject ($connection[$i+1] -creplace ".*_MAP_CONNECTION","") -Header currentmap,connectedmap,connectionxoffset,connectionoffset,connectedblocks,addthree
        Set-Variable $directions[$i] -Value $ConnectionObject
    }
    return Create-MapConnectionsTable -North $NORTH -South $SOUTH -East $EAST -West $WEST
}

function Get-MapBorder {
    param([Parameter(Mandatory=$True,Position=0)][String]$MapName)
    $value = Get-ASMDataLine "$basepath/data/mapObjects/$MapName.asm" $POKERED_BORDER
}

#Helper function for creating the compass object. Note the default value of $null
function Create-MapConnectionsTable {
    param([Parameter(Mandatory=$False,Position=0)][Object]$North = $null,
        [Parameter(Mandatory=$False,Position=1)][Object]$South = $null,
        [Parameter(Mandatory=$False,Position=2)][Object]$East = $null,
        [Parameter(Mandatory=$False,Position=3)][Object]$West = $null)
    return @{"north" = $North; "south" = $South; "east" = $East; "west" = $West}
}

#clean these up
function Convert-MapBytesToText {
    param([Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True)][String]$File,
        [Parameter(Mandatory=$False)][Int]$Width)
    $Width = $Width*4
    $formattedbytes = ([System.Text.Encoding]::UTF8.GetBytes($File)) | Foreach-Object {$_.toString().PadLeft(3," ")}
    $formattedbytes = $formattedbytes -join ','
    if($Width) {$formattedbytes = $formattedbytes -replace "(.{$Width})","`$1`n"}
    $formattedbytes
}

function Convert-MapStringToBytes {
    param([Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True)][String]$In)
    [System.Text.Encoding]::UTF8.GetString(($In -replace "[ `n]", "") -split ',')
}
