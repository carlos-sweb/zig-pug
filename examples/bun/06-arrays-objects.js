/**
 * Example 6: Arrays and Objects Support (Bun.js)
 * Demonstrates setting and using arrays and objects in templates
 */

const zigpug = require('../../nodejs');

console.log('=== Arrays and Objects Example (Bun.js) ===\n');

const template = `
doctype html
html(lang="en")
  head
    title #{pageTitle}
  body
    h1 Team Dashboard

    div.team
      h2 Team: #{team.name}
      p Department: #{team.department}

      h3 Members
      ul
        each member in team.members
          li #{member.name} - #{member.position}

    div.tasks
      h2 Tasks
      each task in tasks
        div.task
          h3= task.title
          p Priority: #{task.priority}
          p Status: #{task.status}
          ul
            each tag in task.tags
              li.tag= tag
`;

const compiler = new zigpug.PugCompiler();

const html = compiler.render(template, {
    pageTitle: 'Team Dashboard',
    team: {
        name: 'Engineering',
        department: 'Product Development',
        members: [
            { name: 'Alice', position: 'Lead Developer' },
            { name: 'Bob', position: 'Frontend Developer' },
            { name: 'Carol', position: 'Backend Developer' }
        ]
    },
    tasks: [
        {
            title: 'Implement authentication',
            priority: 'High',
            status: 'In Progress',
            tags: ['security', 'backend', 'urgent']
        },
        {
            title: 'Design new UI',
            priority: 'Medium',
            status: 'Planning',
            tags: ['design', 'frontend', 'ux']
        },
        {
            title: 'Write documentation',
            priority: 'Low',
            status: 'Not Started',
            tags: ['docs', 'maintenance']
        }
    ]
});

console.log('HTML Output:');
console.log(html);

console.log('\n✓ Bun.js with arrays and objects works great!');
console.log('⚡ Bun.js is 2-5x faster than Node.js!');
