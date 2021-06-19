import {
    ROOT_ID,
} from '@cypress/mount-utils'

export function mount(elementName, properties, attributes) {
    return cy.then(async () => {
        const rootElement = document.getElementById(ROOT_ID);

        if (!rootElement) {
            throw new Error(
                [
                    '[strictly] \U0001f525 Hmm, cannot find root element to mount the component.',
                ].join(' '),
            );
        }

        const targetElement = document.createElement(elementName);

        await import(`../../${elementName.replace(/-/g, '/')}.sly`);

        rootElement.appendChild(targetElement);

        Object.entries(properties).forEach(([propertyName, propertyValue]) => {
            targetElement[propertyName] = propertyValue;
        })

        Object.entries(attributes).forEach(([attributeName, attributeValue]) => {
            targetElement.setAttribute(attributeName, attributeValue);
        })

        return cy.wrap(targetElement);
    });
}