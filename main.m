clc;
clear;
close all;

img = imread('test5.jpg');
imgEnhanced = imadjust(rgb2gray(img));
imgEnhanced = imsharpen(imgEnhanced);

results = ocr(imgEnhanced, 'LayoutAnalysis', 'Block');

figure;
imshow(img);
title('OCR');
for i = 1:length(results.Words)
    wordBBox = results.WordBoundingBoxes(i,:);
    rectangle('Position', wordBBox, 'EdgeColor', 'r', 'LineWidth', 2);
    text(wordBBox(1), wordBBox(2) - 10, results.Words{i}, 'BackgroundColor', [1 1 1]);
end

disp('Recognized text:');
disp(results.Text);
expression = strtrim(results.Text);
expression = expression(~isspace(expression));

function result = isOperator(ch)
    ops = '+-*/';
    result = any(ops == ch);
end

if isOperator(expression(1))
    try
        processPrefix(expression);
    catch
        processInfix(expression);
    end
elseif isOperator(expression(end))
    try
    processPostfix(expression);
    catch
        processInfix(expression);
    end
else
    processInfix(expression);
end   

function [infix] = prefixToInfix(prefix)
    stack = {};
    stackTop = 0;

    function push(element)
        stackTop = stackTop + 1;
        stack{stackTop} = element; 
    end

    function [element] = pop()
        if stackTop == 0
            error('Stack is empty. Cannot perform pop operation.');
        end
        element = stack{stackTop};
        stackTop = stackTop - 1;
    end

    for i = length(prefix):-1:1
        ch = prefix(i);
        if (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
            push(ch);
        else
            operand1 = pop();
            operand2 = pop();
            temp = ['(', operand1, ' ', ch, ' ', operand2, ')'];
            push(temp);
        end
    end

    infix = pop();
    if stackTop ~= 0
        warning('Conversion may not be accurate. Please check the input prefix expression.');
    end
end

function [postfix] = prefixToPostfix(prefix)
    stack = {};
    stackTop = 0;

    function push(element)
        stackTop = stackTop + 1;
        stack{stackTop} = element; 
    end

    function [element] = pop()
        if stackTop == 0
            error('Stack is empty. Cannot perform pop operation.');
        end
        element = stack{stackTop};
        stackTop = stackTop - 1;
    end

    for i = length(prefix):-1:1
        ch = prefix(i);                      
        if (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
            push(ch);
        else
            operand1 = pop();
            operand2 = pop();
            temp = [operand1, operand2, ch];   
            push(temp);
        end
    end

    postfix = pop();
    if stackTop ~= 0
        warning('Conversion may not be accurate. Please check the input prefix expression.');
    end
end

function [postfix] = infixToPostfix(infix)
    precedence = containers.Map({'+', '-', '*', '/'}, {1, 1, 2, 2});

    opStack = {};
    output = {};

    for ch = infix
        if (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
            output{end+1} = ch;
        elseif ch == '('
            opStack{end+1} = ch;
        elseif ch == ')'
            while ~isempty(opStack) && opStack{end} ~= '('
                output{end+1} = opStack{end};
                opStack(end) = [];
            end
            opStack(end) = [];
        else
            while ~isempty(opStack) && precedence(opStack{end}) >= precedence(ch)
                output{end+1} = opStack{end};
                opStack(end) = [];
            end
            opStack{end+1} = ch;
        end
    end
    while ~isempty(opStack)
        output{end+1} = opStack{end};
        opStack(end) = [];
    end
    postfix = strjoin(output, '');
end

function prefix = postfixToPrefix(postfix)
    stack = {};
    for i = 1:length(postfix)
        ch = postfix(i);
        if (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
            stack{end+1} = ch; 
        else
            if length(stack) >= 2
                op2 = stack{end}; stack(end) = []; 
                op1 = stack{end}; stack(end) = []; 

                temp = [ch op1 op2];
                stack{end+1} = temp;
            else
                error('Invalid Postfix Expression');
            end

        end
    end

    if isscalar(stack)
        prefix = stack{end};
    else
        error('Invalid Postfix Expression');
    end
end

function result = evaluatePostfix(expression)
    stack = [];

    for i = 1:length(expression)
        char = expression(i);

        if isstrprop(char, 'digit')
            stack(end+1) = str2double(char);
        else
            if length(stack) >= 2
                operand2 = stack(end);
                stack(end) = [];
                operand1 = stack(end);
                stack(end) = [];

                switch char
                    case '+'
                        stack(end+1) = operand1 + operand2;
                    case '-'
                        stack(end+1) = operand1 - operand2;
                    case '*'
                        stack(end+1) = operand1 * operand2;
                    case '/'
                        stack(end+1) = operand1 / operand2;
                    otherwise
                        error('Unsupported operation');
                end
            else
                error('Invalid postfix expression');
            end
        end
    end

    if isscalar(stack)
        result = stack(1);
    else
        error('Invalid postfix expression');
    end
end


function result = processPrefix(prefix)
    infix = prefixToInfix(prefix);
    postfix = prefixToPostfix(prefix);
    try
    result = "Value: " + evaluatePostfix(postfix) + " | " + " Infix: " + infix + " | " + " Postfix: " + postfix;
    catch
        result = "Value: " + "Error" + " | " + " Infix: " + infix + " | " + " Postfix: " + postfix;
    end
    disp(result)
end

function result = processInfix(infix)
    postfix = infixToPostfix(infix);
    prefix = postfixToPrefix(postfix);
    try
        result = "Value: " + evaluatePostfix(postfix) + " | " + " Prefix: " + prefix + " | " + " Postfix: " + postfix;
    catch
        result = "Value: " + "Error" + " | " + " Prefix: " + prefix + " | " + " Postfix: " + postfix;
    end
    disp(result)
end    


function result = processPostfix(postfix)
    prefix = postfixToPrefix(postfix);
    infix = prefixToInfix(prefix);
    try
        result = "Value: " + evaluatePostfix(postfix) + " | " + " Prefix: " + prefix + " | " + " Infix: " + infix;
    catch  
        result = "Value: " + "Error" + " | " + " Prefix: " + prefix + " | " + " Infix: " + infix;
    end
    disp(result)
end

