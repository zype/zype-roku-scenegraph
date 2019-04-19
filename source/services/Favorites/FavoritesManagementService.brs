function FavoritesManagementService() as object
    this = {}
    this.global = m.global

    this.SetFavoriteIds = function(fav_ids as object) as void
        if m.global.favorite_ids <> invalid then m.global.setField("favorite_ids", fav_ids) else m.global.AddFields({"favorite_ids": fav_ids})
    end function

    this.AddFavorite = function(id as string) as void
        fav_ids = m.global.favorite_ids
        if fav_ids.DoesExist(id) = false then fav_ids[id] = id
        m.global.setField("favorite_ids", fav_ids)
    end function

    this.RemoveFavorite = function(id as string) as void
        fav_ids = m.global.favorite_ids
        if fav_ids.DoesExist(id) then fav_ids.Delete(id)
        m.global.setField("favorite_ids", fav_ids)
    end function

    this.FavoriteExists = function(id as string) as boolean
        m.global.favorite_ids.DoesExist(id)
    end function

    return this
end function
