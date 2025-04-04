//
//  PDFContextEncoder.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2025 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

extension PDFContext {
    
    public enum EncodeError: Error, CaseIterable {
        
        case unsupportedColorSpace
    }
    
    public func data(properties: [PropertyKey: Any] = [:]) throws -> Data {
        
        let document = try self._document(properties: properties)
        
        var data = Data()
        data.append(utf8: "%PDF-1.3\n")
        
        let trailer = document._trailer
        let xref_table = trailer.xref.sorted { $0.key < $1.key }
        
        var xref: [Int] = []
        
        for (_xref, object) in xref_table {
            xref.append(data.count)
            data.append(utf8: "\(_xref.object) 0 obj\n")
            object.encode(&data)
            data.append(utf8: "\nendobj\n")
        }
        
        let startxref = data.count
        
        data.append(utf8: "xref\n0 \(xref.count + 1)\n0000000000 65535 f \n")
        
        for x in xref {
            data.append(utf8: "\("0000000000\(x)".suffix(10)) 00000 n \n")
        }
        
        data.append(utf8: "trailer\n")
        
        trailer.encode(&data)
        
        data.append(utf8: "\nstartxref\n\(startxref)\n%%EOF\n")
        
        return data
    }
    
    public func document(properties: [PropertyKey: Any] = [:]) throws -> PDFDocument {
        return try PDFDocument(self._document(properties: properties)._trailer.dereferenceAll())
    }
    
    private func _document(properties: [PropertyKey: Any] = [:]) throws -> PDFDocument {
        
        var xref_table: [PDFXref: PDFObject] = [:]
        var _pages: [PDFXref] = []
        
        let pages_token = PDFXref(object: xref_table.count + 1, generation: 0)
        xref_table[pages_token] = [:]
        
        for page in self.pages {
            
            var _page = try page.page(&xref_table)
            _page.object["Parent"] = PDFObject(pages_token)
            
            let page_token = PDFXref(object: xref_table.count + 1, generation: 0)
            xref_table[page_token] = _page.object
            
            _pages.append(page_token)
        }
        
        let pages: PDFObject = [
            "Type": PDFObject("Pages" as PDFName),
            "Count": PDFObject(_pages.count),
            "Kids": PDFObject(_pages.map { PDFObject($0) }),
        ]
        
        xref_table[pages_token] = pages
        
        let catalog: PDFObject = [
            "Type": PDFObject("Catalog" as PDFName),
            "Pages": PDFObject(pages_token),
        ]
        
        let catalog_token = PDFXref(object: xref_table.count + 1, generation: 0)
        xref_table[catalog_token] = catalog
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let date = PDFObject("D:\(dateFormatter.string(from: Date()))Z00'00'")
        
        let trailer: PDFObject = [
            "Size": PDFObject(xref_table.count + 1),
            "Root": PDFObject(catalog_token),
            "Info": [
                "Producer": "Doggie PDF Generator",
                "CreationDate": date,
                "ModDate": date
            ],
        ]
        
        solve_duplicate(&xref_table)
        
        return PDFDocument(trailer._apply_xref(xref_table.mapValues { $0.stream.map { PDFObject($0.compressed(properties)) } ?? $0 }))
    }
    
    private func solve_duplicate(_ xref_table: inout [PDFXref: PDFObject]) {
        
        var list: [PDFObject: Int] = [:]
        var map: [PDFObject: PDFXref] = Dictionary(xref_table.map { ($1, $0) }) { lhs, rhs in min(lhs, rhs) }
        
        for item in xref_table.values {
            search_duplicate(item, &list)
        }
        
        for (item, count) in list where count > 1 && map[item] == nil {
            let token = PDFXref(object: xref_table.count + 1, generation: 0)
            xref_table[token] = item
            map[item] = token
        }
        
        for (key, value) in xref_table {
            xref_table[key] = solve_duplicate(value, false, &map)
        }
    }
    
    private func solve_duplicate(_ object: PDFObject, _ flag: Bool, _ map: inout [PDFObject: PDFXref]) -> PDFObject {
        
        var object = object
        let token = map[object]
        
        if let dictionary = object.dictionary {
            
            for (key, value) in dictionary {
                object[key] = solve_duplicate(value, true, &map)
            }
        }
        if let array = object.array {
            object = PDFObject(array.map { solve_duplicate($0, true, &map) })
        }
        
        return flag ? token.map { PDFObject($0) } ?? object : object
    }
    
    private func search_duplicate(_ object: PDFObject, _ list: inout [PDFObject: Int]) {
        
        if let dictionary = object.dictionary {
            
            for item in dictionary.values {
                search_duplicate(item, &list)
            }
            
            list[object, default: 0] += 1
        }
        
        if let array = object.array {
            
            for item in array {
                search_duplicate(item, &list)
            }
            
            list[object, default: 0] += 1
        }
    }
}

extension PDFContext.Page {
    
    func encode_resources(_ resources: PDFContext.PDFResources, _ colorSpace: PDFObject, _ xref_table: inout [PDFXref: PDFObject]) -> PDFXref {
        
        let resources_token = PDFXref(object: xref_table.count + 1, generation: 0)
        xref_table[resources_token] = [:]
        
        var extGState: PDFObject = [:]
        var shading: PDFObject = [:]
        var pattern: PDFObject = [:]
        var xobject: PDFObject = [:]
        
        for (var gstate, name) in resources.extGState {
            gstate["Type"] = PDFObject("ExtGState" as PDFName)
            extGState[name] = gstate
        }
        
        for (name, (var image, mask)) in resources.image {
            
            if var mask = mask {
                
                let mask_token = PDFXref(object: xref_table.count + 1, generation: 0)
                xref_table[mask_token] = PDFObject(mask)
                
                mask["Type"] = PDFObject("XObject" as PDFName)
                mask["Subtype"] = PDFObject("Image" as PDFName)
                image["SMask"] = PDFObject(mask_token)
            }
            
            image["Type"] = PDFObject("XObject" as PDFName)
            image["Subtype"] = PDFObject("Image" as PDFName)
            
            if image["ColorSpace"] == nil {
                image["ColorSpace"] = colorSpace
            }
            
            let image_token = PDFXref(object: xref_table.count + 1, generation: 0)
            xref_table[image_token] = PDFObject(image)
            
            xobject[name] = PDFObject(image_token)
        }
        
        for (name, commands) in resources.mask {
            
            var xobj = PDFStream(dictionary: [
                "Type": PDFObject("XObject" as PDFName),
                "Subtype": PDFObject("Form" as PDFName),
                "FormType": 1,
                "Matrix": [1, 0, 0, 1, 0, 0],
                "BBox": PDFObject(self.media),
                "Resources": PDFObject(resources_token),
                "Group": [
                    "S": PDFObject("Transparency" as PDFName),
                    "CS": PDFObject("DeviceGray" as PDFName),
                    "I": true,
                    "K": false,
                ],
            ])
            
            commands.encode(&xobj.data)
            
            let xobj_token = PDFXref(object: xref_table.count + 1, generation: 0)
            xref_table[xobj_token] = PDFObject(xobj)
            
            extGState[name] = [
                "Type": PDFObject("ExtGState" as PDFName),
                "SMask": [
                    "Type": PDFObject("Mask" as PDFName),
                    "S": PDFObject("Luminosity" as PDFName),
                    "G": PDFObject(xobj_token),
                ],
            ]
        }
        
        for (shader, name) in resources.shading {
            
            switch shader {
                
            case let shader as PDFContext.PDFShading:
                
                let function: PDFObject
                
                switch shader.function.type {
                case 2, 3, 4: function = shader.function.pdf_object
                default: continue
                }
                
                let function_token = PDFXref(object: xref_table.count + 1, generation: 0)
                xref_table[function_token] = function
                
                let _shading: PDFObject
                
                switch shader.type {
                case 1:
                    
                    _shading = [
                        "ColorSpace": shader.deviceGray ? PDFObject("DeviceGray" as PDFName) : colorSpace,
                        "ShadingType": PDFObject(shader.type),
                        "Function": PDFObject(function_token),
                    ]
                    
                case 2, 3:
                    
                    _shading = [
                        "ColorSpace": shader.deviceGray ? PDFObject("DeviceGray" as PDFName) : colorSpace,
                        "ShadingType": PDFObject(shader.type),
                        "Function": PDFObject(function_token),
                        "Coords": PDFObject(shader.coords),
                        "Extend": PDFObject([PDFObject(shader.e0), PDFObject(shader.e1)]),
                    ]
                    
                default: continue
                }
                
                shading[name] = _shading
                
            case let shader as PDFContext.PDFMeshShading:
                
                var data = Data()
                
                let _coord = shader.coord.flatMap { $0.coord }
                let _color = shader.color.joined()
                
                guard let (min_x, max_x) = _coord.lazy.map({ $0.x }).minAndMax() else { break }
                guard let (min_y, max_y) = _coord.lazy.map({ $0.y }).minAndMax() else { break }
                
                let min_color = (0..<shader.numberOfComponents).map { i in min(0, _color.lazy.map { $0[i] }.min() ?? 0) }
                let max_color = (0..<shader.numberOfComponents).map { i in max(1, _color.lazy.map { $0[i] }.max() ?? 1) }
                
                var decode: [PDFObject] = [PDFObject(min_x), PDFObject(max_x), PDFObject(min_y), PDFObject(max_y)]
                decode += zip(min_color, max_color).flatMap { [PDFObject($0), PDFObject($1)] }
                
                for (coord, color) in zip(shader.coord, shader.color) {
                    data.append(UInt8(coord.flag))
                    for point in coord.coord {
                        data.encode(BEUInt32(((point.x - min_x) / (max_x - min_x) * 4294967295).clamped(to: 0...4294967295)))
                        data.encode(BEUInt32(((point.y - min_y) / (max_y - min_y) * 4294967295).clamped(to: 0...4294967295)))
                    }
                    for c in color {
                        for (c, (min, max)) in zip(c, zip(min_color, max_color)) {
                            data.encode(UInt8(((c - min) / (max - min) * 255).clamped(to: 0...255)))
                        }
                    }
                }
                
                let _shading = PDFStream(dictionary: [
                    "ColorSpace": shader.deviceGray ? PDFObject("DeviceGray" as PDFName) : colorSpace,
                    "ShadingType": PDFObject(shader.type),
                    "BitsPerCoordinate": 32,
                    "BitsPerComponent": 8,
                    "BitsPerFlag": 8,
                    "Decode": PDFObject(decode),
                ], data: data)
                
                let shading_token = PDFXref(object: xref_table.count + 1, generation: 0)
                xref_table[shading_token] = PDFObject(_shading)
                
                shading[name] = PDFObject(shading_token)
                
            default: break
            }
        }
        
        for (name, _pattern) in resources.pattern {
            
            var xobj = PDFStream(dictionary: [
                "Type": PDFObject("Pattern" as PDFName),
                "PatternType": PDFObject(_pattern.type),
                "PaintType": PDFObject(_pattern.paintType),
                "TilingType": PDFObject(_pattern.tilingType),
                "BBox": PDFObject(_pattern.bound),
                "XStep": PDFObject(_pattern.xStep),
                "YStep": PDFObject(_pattern.yStep),
                "Resources": PDFObject(self.encode_resources(_pattern.resources, colorSpace, &xref_table)),
                "Matrix": PDFObject(_pattern.transform),
            ])
            
            _pattern.commands.encode(&xobj.data)
            
            let xobj_token = PDFXref(object: xref_table.count + 1, generation: 0)
            xref_table[xobj_token] = PDFObject(xobj)
            
            pattern[name] = PDFObject(xobj_token)
        }
        
        for (commands, name) in resources.transparency_layers {
            
            var xobj = PDFStream(dictionary: [
                "Type": PDFObject("XObject" as PDFName),
                "Subtype": PDFObject("Form" as PDFName),
                "FormType": 1,
                "Matrix": [1, 0, 0, 1, 0, 0],
                "BBox": PDFObject(self.media),
                "Resources": PDFObject(resources_token),
                "Group": [
                    "S": PDFObject("Transparency" as PDFName),
                    "I": true,
                    "K": false,
                ],
            ])
            
            commands.encode(&xobj.data)
            
            let xobj_token = PDFXref(object: xref_table.count + 1, generation: 0)
            xref_table[xobj_token] = PDFObject(xobj)
            
            xobject[name] = PDFObject(xobj_token)
        }
        
        var _resources: PDFObject = [
            "ProcSet": [
                PDFObject("PDF" as PDFName),
                PDFObject("ImageB" as PDFName),
                PDFObject("ImageC" as PDFName),
                PDFObject("ImageI" as PDFName),
            ],
            "ColorSpace": ["Cs1": colorSpace],
        ]
        
        _resources["ExtGState"] = extGState.count == 0 ? nil : extGState
        _resources["Shading"] = shading.count == 0 ? nil : shading
        _resources["Pattern"] = pattern.count == 0 ? nil : pattern
        _resources["XObject"] = xobject.count == 0 ? nil : xobject
        
        xref_table[resources_token] = _resources
        
        return resources_token
    }
    
    func page(_ xref_table: inout [PDFXref: PDFObject]) throws -> PDFPage {
        
        guard let iccData = self.colorSpace.iccData else { throw PDFContext.EncodeError.unsupportedColorSpace }
        
        var page = PDFPage()
        
        page.mediaBox = self.media
        page.cropBox = self._mirrored_crop
        page.bleedBox = self._mirrored_bleed
        page.trimBox = self._mirrored_trim
        page.artBox = self._mirrored_margin
        
        var commands = PDFStream()
        self.finalize().encode(&commands.data)
        
        let commands_token = PDFXref(object: xref_table.count + 1, generation: 0)
        xref_table[commands_token] = PDFObject(commands)
        
        page.object["Contents"] = PDFObject(commands_token)
        
        let rangeOfComponents = (0..<self.colorSpace.numberOfComponents).map { self.colorSpace.rangeOfComponent($0) }.flatMap { [$0.lowerBound, $0.upperBound] }
        let icc_object = PDFObject(["N": PDFObject(self.colorSpace.numberOfComponents), "Range": PDFObject(rangeOfComponents)], iccData)
        
        let icc_object_token = PDFXref(object: xref_table.count + 1, generation: 0)
        xref_table[icc_object_token] = icc_object
        
        let colorSpace: PDFObject = [PDFObject("ICCBased" as PDFName), PDFObject(icc_object_token)]
        
        page.resources = PDFObject(self.encode_resources(self.resources, colorSpace, &xref_table))
        
        return page
    }
}
