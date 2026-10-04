import fetch from 'node-fetch'
import express from 'express'
import path from 'path'
import fs from 'fs'
import mergeJSON from 'merge-json'
import exifParser from 'exif-parser'

const app = express();
const __dirname = path.resolve();

const PORT = Number(process.env.PORT) || 3000;

app.use(express.static('public'));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

const modelMap = {
    "AC002": "DJI Osmo Action 3"
}

const photoSections = [
    { key: 'personal-work', label: 'Personal Work', folder: 'Personal Work' },
    { key: 'illini-swim-club', label: 'Illini Swim Club', folder: 'illini-swim-club' },
    { key: 'illini-solar-car', label: 'Illini Solar Car', folder: 'illini-solar-car' }
];

function getPhotoSection(sectionKey) {
    return photoSections.find((section) => section.key === sectionKey) || photoSections[0];
}

function getSectionPhotos(photoDir, section) {
    const folderPath = section.folder ? path.join(photoDir, section.folder) : photoDir;
    try {
        const files = fs.readdirSync(folderPath).filter(f => /\.(jpe?g|png|gif|webp|svg)$/i.test(f));
        return files.map((fileName) => {
            const filePath = path.join(folderPath, fileName);
            let settings = '';
            try {
                const buffer = fs.readFileSync(filePath);
                const parser = exifParser.create(buffer);
                const result = parser.parse();
                if (result.tags) {
                    const aperture = result.tags.FNumber ? `Aperture: f/${result.tags.FNumber}` : '';
                    const shutter = result.tags.ExposureTime ? `Shutter Speed: 1/${Math.round(1 / result.tags.ExposureTime)}s` : '';
                    const iso = result.tags.ISO ? `ISO: ${result.tags.ISO}` : '';
                    let model = result.tags.Model;
                    model = modelMap[model] || model || '';
                    model = model ? `Model: ${model}` : '';
                    const focalLength = result.tags.FocalLength ? `Focal Length: ${result.tags.FocalLength}mm` : '';
                    settings = [aperture, shutter, iso, model].filter(s => s).join('| ');
                    settings = [model, shutter, aperture, iso, focalLength].filter(s => s).join(' | ');
                }
            } catch (e) {
                // ignore EXIF errors
            }
            const relativeDir = section.folder ? `/images/photos/${encodeURIComponent(section.folder)}` : '/images/photos';
            return { src: `${relativeDir}/${encodeURIComponent(fileName)}`, settings };
        });
    } catch (err) {
        return [];
    }
}

// Front-end page routes

app.get('/', (req, res) => {
    let maindata = JSON.parse(fs.readFileSync('json/main.json'));
    let projectdata = JSON.parse(fs.readFileSync('json/projects.json'));
    let globaldata = JSON.parse(fs.readFileSync('json/global.json'));

    let data = mergeJSON.merge(mergeJSON.merge(maindata, projectdata), globaldata);
    res.render('main', data);
});

app.get('/project', (req, res) => {
    const slug = req.query.slug;
    var projects = JSON.parse(fs.readFileSync('json/projects.json')).projects;
    let projdata = null;
    let globaldata = JSON.parse(fs.readFileSync('json/global.json'));
    for (let i = 0; i < projects.length; i += 1) {
        if (projects[i].slug == slug) {
            projdata = projects[i];
            break;
        }
    }

    let data = mergeJSON.merge(globaldata, projdata);
    res.render('project', data);
});

app.get('/resume', (req, res) => {
    let maindata = JSON.parse(fs.readFileSync('json/main.json'));
    let projectdata = JSON.parse(fs.readFileSync('json/projects.json'));
    let globaldata = JSON.parse(fs.readFileSync('json/global.json'));

    let data = mergeJSON.merge(mergeJSON.merge(maindata, projectdata), globaldata);
    
    res.render('resume', data);
});

app.get(["/photos", "/photos/:section"], (req, res) => {
    let maindata = JSON.parse(fs.readFileSync("json/main.json"));
    let globaldata = JSON.parse(fs.readFileSync("json/global.json"));

    const photoDir = path.join(__dirname, 'public', 'images', 'photos');
    const selectedSection = getPhotoSection(req.params.section || 'personal-work');
    const sectionPhotos = getSectionPhotos(photoDir, selectedSection);

    function shuffleArray(array) {
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
    }
    shuffleArray(sectionPhotos);

    let data = mergeJSON.merge(maindata, globaldata);
    data.photoSections = [{ ...selectedSection, photos: sectionPhotos }];
    data.currentSection = selectedSection;

    res.render("photos", data)
})

app.get('/files/:file', (req, res) => {
    res.sendFile(`./public/files/${req.params.file}`);
});

function startServer(port) {
    const server = app.listen(port, () => {
        console.log(`App listening on port ${port}`)
    });

    server.on('error', (err) => {
        if (err.code === 'EADDRINUSE') {
            const nextPort = port + 1;
            console.warn(`Port ${port} is busy, trying ${nextPort} instead.`);
            startServer(nextPort);
            return;
        }

        throw err;
    });
}

startServer(PORT);
