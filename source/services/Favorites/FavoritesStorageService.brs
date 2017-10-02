'****************************************************
' FavoritesStorageService
'    - used to handle storage of local favorites
'
' Dependencies
'     source/utils.brs

function FavoritesStorageService() as object
    this = {}

    this.AddFavorite = function(video_id as string) as void
        RegWrite(video_id, video_id, "Favorites")
    end function

    this.DeleteFavorite = function(video_id as string) as void
        RegDelete(video_id, "Favorites")
    end function

    this.FavoriteDoesExist = function(video_id as string) as boolean
        favorite = RegRead(video_id, "Favorites")
        if favorite <> invalid then return true else return false
    end function

    this.GetFavoritesIDs = function() as object
        return RegReadSectionKeys("Favorites")
    end function

    this.ClearFavorites = function() as object
        favorite_ids = m.GetFavoritesIDs()

        for each id in favorite_ids
            m.DeleteFavorite(id)
        end for
    end function

    return this
end function
