//
//  LocalMangaDataSource.swift
//  MR-dl
//
//  Created by Chen Zerui on 25/12/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import CoreData
import MRClient

class LocalMangaDataSource{
    
    static let shared = LocalMangaDataSource()
    var series: [MRSerie]
    
    init(){
        series = try! CoreDataHelper.shared.fetchAllSeries()
    }
    
    var numberOfSeries: Int{
        return series.count
    }
    
    func hasSerie(withOid oid: String)-> Bool{
        return series.contains(where: {$0.oid == oid})
    }
    
    func createSerie(withMeta meta: MRSerieMeta)throws {
        let serieRecord = try MRSerie(fromMeta: meta)
        serieRecord.updateInfo(withMeta: meta)
        CoreDataHelper.shared.tryToSave()
    }
    
    func deleteSerie(_ serie: MRSerie)throws {
        try FileManager.default.removeItem(at: serie.directory)
        CoreDataHelper.shared.deleteObject(serie)
    }
    
}