import fetch from 'node-fetch'
import express from 'express'
import path from 'path'
import fs from 'fs'
import mergeJSON from 'merge-json'
import exifParser from 'exif-parser'

const app = express();
const __dirname = path.resolve();

const PORT = process.env.PORT || 3000;

app.use(express.static('public'));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

const modelMap = {
    "AC002": "DJI Osmo Action 3"
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

app.get("/photos", (req, res) => {
    let maindata = JSON.parse(fs.readFileSync("json/main.json"));
    let globaldata = JSON.parse(fs.readFileSync("json/global.json"));

    // Read all image files from public/images/photos and pass to template
    const photoDir = path.join(__dirname, 'public', 'images', 'photos');
    let photos = [];
    try {
        const files = fs.readdirSync(photoDir).filter(f => /\.(jpe?g|png|gif|webp|svg)$/i.test(f));
        photos = files.map(f => {
            const filePath = path.join(photoDir, f);
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
            return { src: `images/photos/${f}`, settings };
        });
    } catch (err) {
        console.warn('Could not read photos directory:', err.message);
    }

    let data = mergeJSON.merge(maindata, globaldata);
    data.photos = photos;

    // Shuffle the photos array for randomization
    function shuffleArray(array) {
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
    }
    shuffleArray(data.photos);

    res.render("photos", data)
})

app.get('/files/:file', (req, res) => {
    res.sendFile(`./public/files/${req.params.file}`);
});

app.listen(PORT, () => {
    console.log(`App listening on port 3000`)
});
