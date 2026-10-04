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
    data.staticSite = true;
    data.header_nav = data.header_nav.map((item) => ({
        ...item,
        link: item.link
            .replace('/resume', 'resume.html')
            .replace('/photos/personal-work', 'photos-personal-work.html')
            .replace('/photos/illini-swim-club', 'photos-illini-swim-club.html')
            .replace('/photos/illini-solar-car', 'photos-illini-solar-car.html')
            .replace('/photos', 'photos.html')
            .replace('/#', 'index.html#')
    }));
    return data;
}

function getPhotosBySection() {
    const photoDir = path.join(projectRoot, 'public', 'images', 'photos');
    const sections = [
        { key: 'personal-work', label: 'Personal Work', folder: 'Personal Work' },
        {
            key: 'illini-swim-club',
            label: 'Illini Swim Club',
            folder: 'illini-swim-club',
            meets: [
                { key: 'mizzou-show-your-strips-2026', label: 'Mizzou Show Your Strips 2026', folder: 'Mizzou Show Your Strips 2026' }
            ]
        },
        { key: 'illini-solar-car', label: 'Illini Solar Car', folder: 'illini-solar-car' }
    ];

    const readSectionPhotos = (section) => {
        const sectionDir = section.folder ? path.join(photoDir, section.folder) : photoDir;
        try {
            return fs.readdirSync(sectionDir)
                .filter((file) => /\.(jpe?g|png|gif|webp|svg)$/i.test(file))
                .map((file) => {
                    let settings = '';
                    try {
                        const result = exifParser.create(fs.readFileSync(path.join(sectionDir, file))).parse();
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
                    const relativeDir = section.folder
                        ? `/images/photos/${section.folder.split(path.sep).map(encodeURIComponent).join('/')}`
                        : '/images/photos';
                    return { src: `${relativeDir}/${encodeURIComponent(file)}`, settings };
                });
        } catch (error) {
            return [];
        }
    };

    return sections.flatMap((section) => [
        { ...section, photos: readSectionPhotos(section) },
        ...(section.meets || []).map((meet) => ({
            ...section,
            ...meet,
            key: section.key,
            folder: path.join(section.folder, meet.folder),
            meetKey: meet.key,
            parentKey: section.key,
            parentLabel: section.label,
            photos: readSectionPhotos({ ...section, ...meet, folder: path.join(section.folder, meet.folder) })
        }))
    ]);
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
const photoSections = [
    { key: 'personal-work', label: 'Personal Work', folder: 'Personal Work' },
    {
        key: 'illini-swim-club',
        label: 'Illini Swim Club',
        folder: 'illini-swim-club',
        meets: [
            { key: 'mizzou-show-your-strips-2026', label: 'Mizzou Show Your Strips 2026', folder: 'Mizzou Show Your Strips 2026' }
        ]
    },
    { key: 'illini-solar-car', label: 'Illini Solar Car', folder: 'illini-solar-car' }
];

fs.writeFileSync(path.join(outputRoot, 'index.html'), render('main', data));
fs.writeFileSync(path.join(outputRoot, 'resume.html'), render('resume', data));

photoSections.forEach((section) => {
    const sectionPhotos = getPhotosBySection().find((item) => item.key === section.key)?.photos || [];
    const outputName = section.key === 'personal-work' ? 'photos.html' : `photos-${section.key}.html`;
    fs.writeFileSync(path.join(outputRoot, outputName), render('photos', {
        ...data,
        photoSections: [{ ...section, photos: sectionPhotos }]
    }));

    (section.meets || []).forEach((meet) => {
        const meetData = getPhotosBySection().find((item) => item.meetKey === meet.key);
        fs.writeFileSync(path.join(outputRoot, `photos-${section.key}-${meet.key}.html`), render('photos', {
            ...data,
            photoSections: [{ ...meetData, photos: meetData?.photos || [] }]
        }));
    });
});

for (const project of data.projects) {
    fs.writeFileSync(path.join(outputRoot, `${project.slug}.html`), render('project', { ...data, ...project }));
}