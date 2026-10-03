import ejs from 'ejs';
import exifParser from 'exif-parser';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const root = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.join(root, '..');
const outputRoot = path.join(projectRoot, 'dist');
const viewsRoot = path.join(projectRoot, 'views');

const readJson = (file) => JSON.parse(fs.readFileSync(path.join(projectRoot, 'json', file), 'utf8'));
const modelMap = { AC002: 'DJI Osmo Action 3' };

function localPath(value) {
    if (typeof value !== 'string') return value;
    return value.replace(/\/(images|files|css)\//g, '$1/');
}

function prepareData(data) {
    if (Array.isArray(data)) return data.map(prepareData);
    if (data && typeof data === 'object') {
        return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, prepareData(value)]));
    }
    return localPath(data);
}

function pageData() {
    const main = prepareData(readJson('main.json'));
    const projects = prepareData(readJson('projects.json'));
    const global = prepareData(readJson('global.json'));
    const data = { ...global, ...main, ...projects };
    data.header_nav = data.header_nav.map((item) => ({
        ...item,
        link: item.link.replace('/resume', 'resume.html').replace('/photos', 'photos.html').replace('/#', 'index.html#')
    }));
    return data;
}

function getPhotos() {
    const photoDir = path.join(projectRoot, 'public', 'images', 'photos');
    return fs.readdirSync(photoDir)
        .filter((file) => /\.(jpe?g|png|gif|webp|svg)$/i.test(file))
        .map((file) => {
            let settings = '';
            try {
                const result = exifParser.create(fs.readFileSync(path.join(photoDir, file))).parse();
                const tags = result.tags || {};
                const model = modelMap[tags.Model] || tags.Model || '';
                const shutter = tags.ExposureTime ? `Shutter Speed: 1/${Math.round(1 / tags.ExposureTime)}s` : '';
                const aperture = tags.FNumber ? `Aperture: f/${tags.FNumber}` : '';
                const iso = tags.ISO ? `ISO: ${tags.ISO}` : '';
                const focalLength = tags.FocalLength ? `Focal Length: ${tags.FocalLength}mm` : '';
                settings = [model && `Model: ${model}`, shutter, aperture, iso, focalLength].filter(Boolean).join(' | ');
            } catch (error) {
                // Some image formats do not contain readable EXIF data.
            }
            return { src: `images/photos/${file}`, settings };
        });
}

function render(view, data) {
    const html = ejs.render(fs.readFileSync(path.join(viewsRoot, `${view}.ejs`), 'utf8'), data, {
        views: viewsRoot,
        filename: path.join(viewsRoot, `${view}.ejs`)
    });
    return html.replaceAll('href="/"', 'href="index.html"');
}

fs.rmSync(outputRoot, { recursive: true, force: true });
fs.cpSync(path.join(projectRoot, 'public'), outputRoot, { recursive: true });
fs.writeFileSync(path.join(outputRoot, '.nojekyll'), '');

const data = pageData();
fs.writeFileSync(path.join(outputRoot, 'index.html'), render('main', data));
fs.writeFileSync(path.join(outputRoot, 'resume.html'), render('resume', data));
fs.writeFileSync(path.join(outputRoot, 'photos.html'), render('photos', { ...data, photos: getPhotos() }));

for (const project of data.projects) {
    fs.writeFileSync(path.join(outputRoot, `${project.slug}.html`), render('project', { ...data, ...project }));
}